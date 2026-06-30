import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiService {
  static const String _defaultBaseUrl = 'https://drug-spot.duckdns.org';
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  final String baseUrl;
  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = client ?? http.Client();

  bool get hasToken => _accessToken != null;

  int? get userId {
    if (_accessToken == null) return null;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['user_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ── Token persistence ──

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessKey);
    _refreshToken = prefs.getString(_refreshKey);
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> clearToken() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  // ── HTTP helpers ──

  Map<String, dynamic> _parseJson(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    String message;
    if (body is Map) {
      message =
          (body['error'] ??
                  body['detail'] ??
                  body.values.first?.toString() ??
                  'Request failed')
              .toString();
    } else {
      message = 'Request failed';
    }
    throw ApiException(message, response.statusCode);
  }

  List<dynamic> _parseJsonList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    final body = jsonDecode(response.body);
    final message = body is Map
        ? (body['error'] ?? body['detail'] ?? 'Request failed').toString()
        : 'Request failed';
    throw ApiException(message, response.statusCode);
  }

  Future<http.Response> _authGet(Uri uri) async {
    var response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _client.get(uri, headers: _headers);
    }
    return response;
  }

  Future<http.Response> _authPost(Uri uri, {Object? body}) async {
    var response = await _client.post(uri, headers: _headers, body: body);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _client.post(uri, headers: _headers, body: body);
    }
    return response;
  }

  Future<http.Response> _authPut(Uri uri, {Object? body}) async {
    var response = await _client.put(uri, headers: _headers, body: body);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _client.put(uri, headers: _headers, body: body);
    }
    return response;
  }

  Future<http.Response> _authDelete(Uri uri) async {
    var response = await _client.delete(uri, headers: _headers);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _client.delete(uri, headers: _headers);
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['access'] as String;
        _accessToken = newAccess;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessKey, newAccess);
        return true;
      }
    } catch (_) {}
    await clearToken();
    return false;
  }

  // ── Auth ──

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'user_type': userType,
      }),
    );
    final data = _parseJson(response);
    await _saveTokens(data['access'] as String, data['refresh'] as String);
    return data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = _parseJson(response);
    await _saveTokens(data['access'] as String, data['refresh'] as String);
    return data;
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _authPost(
          Uri.parse('$baseUrl/api/logout'),
          body: jsonEncode({'refresh': _refreshToken}),
        );
      } catch (_) {}
    }
    await clearToken();
  }

  // ── Email Verification ──

  /// Sends (or resends) a 6-digit OTP to the authenticated user's email.
  /// Returns the masked email address (e.g. "j***@example.com").
  Future<String> sendVerificationEmail() async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/send-verification'),
    );
    final data = _parseJson(response);
    return data['email'] as String;
  }

  /// Submits the OTP entered by the user.
  /// Returns the updated user map on success.
  /// Throws [ApiException] on wrong/expired OTP.
  Future<Map<String, dynamic>> verifyEmail(String otp) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/verify-email'),
      body: jsonEncode({'otp': otp}),
    );
    final data = _parseJson(response);
    return data['user'] as Map<String, dynamic>;
  }

  // ── Profile ──

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _authGet(Uri.parse('$baseUrl/api/profile'));
    return _parseJson(response);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _authPut(
      Uri.parse('$baseUrl/api/profile'),
      body: jsonEncode(data),
    );
    return _parseJson(response);
  }

  // ── Pharmacies ──

  Future<List<dynamic>> getPharmacies() async {
    final response = await _authGet(Uri.parse('$baseUrl/api/pharmacies/'));
    return _parseJsonList(response);
  }

  Future<Map<String, dynamic>> getPharmacyById(int id) async {
    final response = await _authGet(Uri.parse('$baseUrl/api/pharmacies/$id'));
    return _parseJson(response);
  }

  Future<Map<String, dynamic>> createPharmacy({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String phone,
    String? accent,
  }) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/pharmacies/'),
      body: jsonEncode({
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        if (accent != null) 'accent': accent,
      }),
    );
    return _parseJson(response);
  }

  Future<Map<String, dynamic>> updatePharmacy(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _authPut(
      Uri.parse('$baseUrl/api/pharmacies/$id'),
      body: jsonEncode(data),
    );
    return _parseJson(response);
  }

  // ── Medicines ──

  Future<List<dynamic>> getMedicines() async {
    final response = await _authGet(Uri.parse('$baseUrl/api/medicines/'));
    return _parseJsonList(response);
  }

  Future<List<dynamic>> getMedicinesByPharmacy(int pharmacyId) async {
    final response = await _authGet(
      Uri.parse('$baseUrl/api/medicines/pharmacy/$pharmacyId'),
    );
    return _parseJsonList(response);
  }

  Future<Map<String, dynamic>> addMedicine(String name, double price) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/medicines/'),
      body: jsonEncode({'name': name, 'price': price}),
    );
    return _parseJson(response);
  }

  Future<void> updateMedicine(int id, String name, double price) async {
    final response = await _authPut(
      Uri.parse('$baseUrl/api/medicines/$id'),
      body: jsonEncode({'name': name, 'price': price}),
    );
    _parseJson(response);
  }

  Future<void> deleteMedicine(int id) async {
    final response = await _authDelete(Uri.parse('$baseUrl/api/medicines/$id'));
    _parseJson(response);
  }

  // ── Medicine Requests ──

  Future<List<dynamic>> getMedicineRequests() async {
    final response = await _authGet(
      Uri.parse('$baseUrl/api/medicine_requests/'),
    );
    return _parseJsonList(response);
  }

  Future<Map<String, dynamic>> addMedicineRequest({
    required String username,
    required String contact,
    required String medicineName,
    String? avatarPath,
    bool useAsset = false,
  }) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/medicine_requests/'),
      body: jsonEncode({
        'username': username,
        'contact': contact,
        'medicine_name': medicineName,
        if (avatarPath != null) 'avatar_path': avatarPath,
        'use_asset': useAsset,
      }),
    );
    return _parseJson(response);
  }

  // ── Conversations ──

  Future<List<dynamic>> getConversations() async {
    final response = await _authGet(Uri.parse('$baseUrl/api/conversations/'));
    return _parseJsonList(response);
  }

  Future<Map<String, dynamic>> startConversation(int userId) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/conversations/start'),
      body: jsonEncode({'user_id': userId}),
    );
    return _parseJson(response);
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    final response = await _authGet(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
    );
    return _parseJsonList(response);
  }

  Future<Map<String, dynamic>> sendMessage(
    int conversationId,
    String text,
  ) async {
    final response = await _authPost(
      Uri.parse('$baseUrl/api/conversations/$conversationId/send'),
      body: jsonEncode({'text': text}),
    );
    return _parseJson(response);
  }

  // ── Notifications ──

  Future<void> registerDeviceToken(String token, String platform) async {
    await _authPost(
      Uri.parse('$baseUrl/api/notifications/device/register'),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _authPost(
      Uri.parse('$baseUrl/api/notifications/device/unregister'),
      body: jsonEncode({'token': token}),
    );
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _authGet(
      Uri.parse('$baseUrl/api/notifications/preferences'),
    );
    return _parseJson(response);
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> data,
  ) async {
    final response = await _authPut(
      Uri.parse('$baseUrl/api/notifications/preferences'),
      body: jsonEncode(data),
    );
    return _parseJson(response);
  }

  String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}:${uri.port}';
  }

  String? get accessToken => _accessToken;
}
