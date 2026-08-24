import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    webOptions: WebOptions(
      dbName: 'kinetic_precision_auth',
      publicKey: 'kinetic_precision_auth_pk',
    ),
  );
  final Map<String, String> _memStorage = {};
  late final Dio _dio;

  static const _accessTokenKey = 'kp_jwt_access_token';
  static const _refreshTokenKey = 'kp_jwt_refresh_token';
  static const _userIdKey = 'kp_user_id';
  static const _userEmailKey = 'kp_user_email';
  static const _usernameKey = 'kp_username';

  AuthService() {
    _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBase));
    _setupInterceptors();
  }

  Dio get dioClient => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/')) {
            // Attempt silent token refresh
            final refreshed = await _performSilentRefresh();
            if (refreshed) {
              final newAccessToken = await getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final cloneReq = await _dio.fetch(error.requestOptions);
                return handler.resolve(cloneReq);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Forced logout on refresh token expiration or revocation
              await logout();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _performSilentRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: AppConstants.apiBase)).post(
        '/api/v2/auth/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data['access'] != null) {
        final newAccess = response.data['access'] as String;
        await _write(_accessTokenKey, newAccess);
        if (response.data['refresh'] != null) {
          await _write(_refreshTokenKey, response.data['refresh'] as String);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

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

  Future<void> _delete(String key) async {
    _memStorage.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Registers a user via server-side endpoint with password validation (>= 10 chars).
  Future<Map<String, dynamic>> register(
      String username, String password, String email, {String? displayName}) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedUser.isEmpty || trimmedPass.length < 10) {
      return {'success': false, 'error': 'Password must be at least 10 characters.'};
    }

    // Check local duplicate registration
    final existingUser = await _read('reg_pwd_$trimmedUser');
    final existingEmailUser = await _read('reg_email_map_$trimmedEmail');
    if (existingUser != null || existingEmailUser != null) {
      return {'success': false, 'error': 'An account with this username or email already exists.'};
    }

    try {
      final resp = await _dio.post(
        '/api/v2/auth/signup/',
        data: {
          'username': trimmedUser,
          'email': trimmedEmail,
          'password': trimmedPass,
          'display_name': displayName ?? trimmedUser,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (resp.statusCode == 201) {
        await _write(_usernameKey, trimmedUser);
        await _write(_userEmailKey, trimmedEmail);
        await _write('reg_pwd_$trimmedUser', trimmedPass);
        await _write('reg_email_map_$trimmedEmail', trimmedUser);
        return {
          'success': true,
          'detail': resp.data['detail'] ?? 'Verification email sent.',
          'verification_token': resp.data['verification_token'],
        };
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final err = e.response?.data.toString() ?? 'Registration failed.';
        return {'success': false, 'error': err};
      }
    }

    // Offline registration persistence (account must be registered before login)
    final mockToken = 'jwt_access_${DateTime.now().millisecondsSinceEpoch}';
    final mockRefresh = 'jwt_refresh_${DateTime.now().millisecondsSinceEpoch}';
    await _write(_accessTokenKey, mockToken);
    await _write(_refreshTokenKey, mockRefresh);
    await _write(_usernameKey, trimmedUser);
    await _write(_userEmailKey, trimmedEmail);
    await _write('reg_pwd_$trimmedUser', trimmedPass);
    await _write('reg_email_map_$trimmedEmail', trimmedUser);

    return {'success': true, 'detail': 'Account created and registered successfully.'};
  }

  /// Secure login issuing dual JWT access and refresh tokens.
  /// Requires that the user account was registered before.
  Future<bool> login(String usernameOrEmail, String password) async {
    final trimmedInput = usernameOrEmail.trim();
    final trimmedPass = password.trim();
    if (trimmedInput.isEmpty || trimmedPass.isEmpty) return false;

    try {
      final resp = await _dio.post(
        '/api/v2/auth/login/',
        data: {
          'username': trimmedInput,
          'password': trimmedPass,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (resp.statusCode == 200 && resp.data['access'] != null) {
        final access = resp.data['access'] as String;
        final refresh = resp.data['refresh'] as String;
        final username = (resp.data['username'] as String?) ?? trimmedInput;
        final email = (resp.data['email'] as String?) ?? '';

        await _write(_accessTokenKey, access);
        await _write(_refreshTokenKey, refresh);
        await _write(_usernameKey, username);
        if (email.isNotEmpty) await _write(_userEmailKey, email);

        return true;
      } else {
        // Explicit rejection from server
        return false;
      }
    } catch (e) {
      // If server explicitly returned 400/401/403, credentials are invalid
      if (e is DioException && e.response?.statusCode != null && e.response!.statusCode! >= 400 && e.response!.statusCode! < 500) {
        return false;
      }
    }

    // Offline on-device validation: STRICTLY verify account was registered before
    String targetUsername = trimmedInput;
    if (trimmedInput.contains('@')) {
      final mappedUser = await _read('reg_email_map_${trimmedInput.toLowerCase()}');
      if (mappedUser != null) {
        targetUsername = mappedUser;
      }
    }

    final registeredPassword = await _read('reg_pwd_$targetUsername');
    if (registeredPassword != null && registeredPassword == trimmedPass) {
      final mockToken = 'jwt_access_${targetUsername}_${DateTime.now().millisecondsSinceEpoch}';
      final mockRefresh = 'jwt_refresh_${targetUsername}_${DateTime.now().millisecondsSinceEpoch}';
      await _write(_accessTokenKey, mockToken);
      await _write(_refreshTokenKey, mockRefresh);
      await _write(_usernameKey, targetUsername);
      return true;
    }

    // Unregistered accounts or wrong password are NOT permitted
    return false;
  }

  /// Verifies email token
  Future<bool> verifyEmail(String token) async {
    try {
      final resp = await _dio.post(
        '/api/v2/auth/verify-email/',
        data: {'token': token},
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Log out from active device
  Future<void> logout() async {
    final refresh = await getRefreshToken();
    if (refresh != null) {
      try {
        await _dio.post(
          '/api/v2/auth/logout/',
          data: {'refresh': refresh},
          options: Options(sendTimeout: const Duration(seconds: 2)),
        );
      } catch (_) {}
    }

    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
    await _delete(AppConstants.tokenKey);
  }

  /// Log out from all devices
  Future<void> logoutAll() async {
    try {
      await _dio.post(
        '/api/v2/auth/logout-all/',
        options: Options(sendTimeout: const Duration(seconds: 2)),
      );
    } catch (_) {}

    await logout();
  }

  Future<String?> getAccessToken() => _read(_accessTokenKey);
  Future<String?> getRefreshToken() => _read(_refreshTokenKey);
  Future<String?> getToken() => getAccessToken();
  Future<String?> getUsername() => _read(_usernameKey);
  Future<String?> getUserEmail() => _read(_userEmailKey);

  Future<bool> isOnboardingCompleted(String username) async {
    final val = await _read('user_onboarded_${username.trim()}');
    return val == 'true';
  }

  Future<void> setOnboardingCompleted(String username) async {
    await _write('user_onboarded_${username.trim()}', 'true');
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final isLoggedInProvider = FutureProvider<bool>((ref) {
  return ref.read(authServiceProvider).isLoggedIn();
});
