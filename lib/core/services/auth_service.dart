import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Change this to your machine's IP when testing on a physical device.
/// Use http://10.0.2.2:8000 for the Android emulator.
const String _kBaseUrl = 'http://10.0.2.2:8000/api';

// ─── Storage keys ──────────────────────────────────────────────────────────
const _kAccessToken = 'auth_access_token';
const _kRefreshToken = 'auth_refresh_token';
const _kUserJson = 'auth_user_json';

// ─── Data classes ──────────────────────────────────────────────────────────

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String bio;
  final String avatarPath;
  final String userType; // 'pharmacy' | 'patient'

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarPath,
    required this.userType,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        avatarPath: json['avatar_path'] as String? ?? '',
        userType: json['user_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'bio': bio,
        'avatar_path': avatarPath,
        'user_type': userType,
      };

  AuthUser copyWith({
    String? email,
    String? phone,
    String? bio,
    String? avatarPath,
  }) =>
      AuthUser(
        id: id,
        username: username,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        avatarPath: avatarPath ?? this.avatarPath,
        userType: userType,
      );
}

class AuthResult {
  final bool success;
  final String? error;
  final AuthUser? user;

  const AuthResult.ok(this.user)
      : success = true,
        error = null;

  const AuthResult.fail(this.error)
      : success = false,
        user = null;
}

// ─── Service ───────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Public helpers ────────────────────────────────────────────────────────

  Future<AuthUser?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kUserJson);
    if (json == null) return null;
    return AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<String?> get accessToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kAccessToken);
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String userType,
    String bio = '',
  }) async {
    return _authRequest(
      endpoint: 'register',
      body: {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'user_type': userType,
        'bio': bio,
      },
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    return _authRequest(
      endpoint: 'login',
      body: {'username': username, 'password': password},
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_kRefreshToken);

    if (refreshToken != null) {
      try {
        await _post(
          'logout',
          body: {'refresh': refreshToken},
          withAuth: true,
        );
      } catch (_) {
        // Best-effort: clear local tokens regardless
      }
    }

    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUserJson);
  }

  // ── Refresh access token ──────────────────────────────────────────────────

  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_kRefreshToken);
    if (refreshToken == null) return false;

    try {
      final response = await _post('refresh', body: {'refresh': refreshToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await prefs.setString(_kAccessToken, data['access'] as String);
        // If rotation is on, a new refresh token might be returned
        if (data.containsKey('refresh')) {
          await prefs.setString(_kRefreshToken, data['refresh'] as String);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Get profile ───────────────────────────────────────────────────────────

  Future<AuthResult> getProfile() async {
    try {
      final response = await _get('profile', withAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data);
        await _saveUser(user);
        return AuthResult.ok(user);
      }
      return AuthResult.fail(_errorFrom(response));
    } catch (e) {
      return AuthResult.fail(e.toString());
    }
  }

  // ── Update profile ────────────────────────────────────────────────────────

  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    String? bio,
    String? avatarPath,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (avatarPath != null) body['avatar_path'] = avatarPath;

    try {
      final response = await _put('profile', body: body, withAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data);
        await _saveUser(user);
        return AuthResult.ok(user);
      }
      return AuthResult.fail(_errorFrom(response));
    } catch (e) {
      return AuthResult.fail(e.toString());
    }
  }

  // ── Change password ───────────────────────────────────────────────────────

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _post(
        'change-password',
        body: {'old_password': oldPassword, 'new_password': newPassword},
        withAuth: true,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Server returns new tokens — store them
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kAccessToken, data['access'] as String);
        await prefs.setString(_kRefreshToken, data['refresh'] as String);
        return AuthResult.ok(null);
      }
      return AuthResult.fail(_errorFrom(response));
    } catch (e) {
      return AuthResult.fail(e.toString());
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AuthResult> _authRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _post(endpoint, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kAccessToken, data['access'] as String);
        await prefs.setString(_kRefreshToken, data['refresh'] as String);
        await _saveUser(user);
        return AuthResult.ok(user);
      }
      return AuthResult.fail(_errorFrom(response));
    } catch (e) {
      return AuthResult.fail('Network error: $e');
    }
  }

  Future<void> _saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, jsonEncode(user.toJson()));
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken) ?? '';
    return {
      ..._jsonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _post(
    String endpoint, {
    Map<String, dynamic> body = const {},
    bool withAuth = false,
  }) async {
    final headers =
        withAuth ? await _authHeaders() : _jsonHeaders;
    return http.post(
      Uri.parse('$_kBaseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _get(
    String endpoint, {
    bool withAuth = false,
  }) async {
    final headers =
        withAuth ? await _authHeaders() : _jsonHeaders;
    return http.get(
      Uri.parse('$_kBaseUrl/$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> _put(
    String endpoint, {
    Map<String, dynamic> body = const {},
    bool withAuth = false,
  }) async {
    final headers =
        withAuth ? await _authHeaders() : _jsonHeaders;
    return http.put(
      Uri.parse('$_kBaseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  String _errorFrom(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data.containsKey('error')) return data['error'] as String;
        // DRF field errors — join them
        final messages = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            messages.add(value.join(', '));
          } else {
            messages.add(value.toString());
          }
        });
        return messages.join('\n');
      }
    } catch (_) {}
    return 'Server error (${response.statusCode})';
  }
}
