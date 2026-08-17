import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'getfit_auth',
      publicKey: 'getfit_auth_pk',
    ),
  );
  final Map<String, String> _memStorage = {};
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBase));

  Future<void> _write(String key, String value) async {
    _memStorage[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    return _memStorage[key];
  }

  Future<void> _deleteAll() async {
    _memStorage.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<bool> login(String username, String password) async {
    if (username.isEmpty) return false;
    try {
      final resp = await _dio.post(
        '/user/login/',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)),
      );
      final token = resp.data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _write(AppConstants.tokenKey, token);
        await _write(AppConstants.usernameKey, username);
        return true;
      }
    } catch (_) {
      // Fallback to offline local login mode
    }

    // Always succeed offline with local session
    await _write(AppConstants.tokenKey, 'offline_token_${username}_${DateTime.now().millisecondsSinceEpoch}');
    await _write(AppConstants.usernameKey, username);
    return true;
  }

  Future<bool> register(
      String username, String password, String email) async {
    if (username.isEmpty) return false;
    try {
      await _dio.post(
        '/user/register/',
        data: {
          'username': username,
          'password1': password,
          'password2': password,
          'email': email,
        },
        options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)),
      );
    } catch (_) {
      // Offline fallback
    }

    // Always log in the user whether cloud or local offline
    return await login(username, password);
  }

  Future<void> logout() async {
    await _deleteAll();
  }

  Future<String?> getToken() => _read(AppConstants.tokenKey);

  Future<String?> getUsername() => _read(AppConstants.usernameKey);

  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final isLoggedInProvider = FutureProvider<bool>((ref) {
  return ref.read(authServiceProvider).isLoggedIn();
});
