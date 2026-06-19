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
  // For Android emulator use 10.0.2.2; for physical device use your PC's local IP
  static const String _defaultBaseUrl = 'http://10.0.2.2:3001';
  static const String _tokenKey = 'jwt_token';

  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  bool get hasToken => _token != null;

  int? get userId {
    if (_token == null) return null;
    try {
      final parts = _token!.split('.');
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
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Token persistence ──

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── HTTP helpers ──

  Future<Map<String, dynamic>> _json(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final message = body is Map
        ? (body['error'] ?? body['detail'] ?? body.values.first?.toString() ?? 'Request failed')
        : 'Request failed';
    throw ApiException(message.toString(), response.statusCode);
  }

  Future<List<dynamic>> _jsonList(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    final body = jsonDecode(response.body);
    final message = body is Map ? (body['error'] ?? body['detail'] ?? 'Request failed') : 'Request failed';
    throw ApiException(message.toString(), response.statusCode);
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
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'user_type': userType,
      }),
    );
    return _json(response);
  }

  Future<String> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = await _json(response);
    final token = data['token'] as String;
    await _saveToken(token);
    return token;
  }

  // ── Profile ──

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
    );
    return _json(response);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
    await _json(response);
  }

  // ── Pharmacies ──

  Future<List<dynamic>> getPharmacies() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pharmacies/'),
      headers: _headers,
    );
    return _jsonList(response);
  }

  Future<Map<String, dynamic>> getPharmacyById(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pharmacies/$id'),
      headers: _headers,
    );
    return _json(response);
  }

  // ── Medicines ──

  Future<List<dynamic>> getMedicines() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/medicines/'),
      headers: _headers,
    );
    return _jsonList(response);
  }

  Future<List<dynamic>> getMedicinesByPharmacy(int pharmacyId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/medicines/pharmacy/$pharmacyId'),
      headers: _headers,
    );
    return _jsonList(response);
  }

  Future<Map<String, dynamic>> addMedicine(String name, double price) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/medicines/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'price': price}),
    );
    return _json(response);
  }

  Future<void> updateMedicine(int id, String name, double price) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/medicines/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'price': price}),
    );
    await _json(response);
  }

  Future<void> deleteMedicine(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/medicines/$id'),
      headers: _headers,
    );
    await _json(response);
  }

  // ── Medicine Requests ──

  Future<List<dynamic>> getMedicineRequests() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/medicine_requests/'),
      headers: _headers,
    );
    return _jsonList(response);
  }

  Future<Map<String, dynamic>> addMedicineRequest({
    required String username,
    required String contact,
    required String medicineName,
    String? avatarPath,
    bool useAsset = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/medicine_requests/'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'contact': contact,
        'medicine_name': medicineName,
        if (avatarPath != null) 'avatar_path': avatarPath,
        'use_asset': useAsset,
      }),
    );
    return _json(response);
  }
}
