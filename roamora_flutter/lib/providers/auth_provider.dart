import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;
  final bool isDuplicateEmail;
  final bool isNewUser;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
    this.isDuplicateEmail = false,
    this.isNewUser = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
    bool? isDuplicateEmail,
    bool? isNewUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isDuplicateEmail: isDuplicateEmail ?? false,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient.instance;
  Future<void>? _ongoingCheckAuth;

  AuthNotifier() : super(AuthState(isLoading: true)) {
    checkAuth();
  }

  Future<void> checkAuth() {
    if (_ongoingCheckAuth != null) return _ongoingCheckAuth!;
    final future = _doCheckAuth();
    _ongoingCheckAuth = future;
    return future.whenComplete(() {
      _ongoingCheckAuth = null;
    });
  }

  Future<void> _doCheckAuth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('[STARTUP] checkAuth: checking stored session token...');
      final token = await SecureStorageService.getSessionToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('[STARTUP] checkAuth: no session token stored.');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        );
        return;
      }

      debugPrint('[STARTUP] checkAuth: validating session with /me endpoint...');
      final data = await _api
          .get(ApiEndpoints.me)
          .timeout(const Duration(seconds: 6));

      if (data != null && data is Map<String, dynamic>) {
        final user = UserModel.fromJson(data);
        await SecureStorageService.saveUserId(user.id);
        await SecureStorageService.saveUserEmail(user.email);
        debugPrint('[STARTUP] checkAuth: session valid for ${user.id} (${user.email})');
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          error: null,
        );
      } else {
        debugPrint('[STARTUP Warning] checkAuth: /me returned non-map payload');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: 'Invalid profile response from server',
        );
      }
    } on ApiException catch (e) {
      debugPrint('[STARTUP Warning] checkAuth session validation failed: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode == 401) {
        await SecureStorageService.clearSessionToken();
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.message,
      );
    } catch (e) {
      debugPrint('[STARTUP Error] checkAuth unexpected error or timeout: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
      debugPrint('[STARTUP] checkAuth completed. Result: isAuthenticated=${state.isAuthenticated}, isLoading=${state.isLoading}');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, isDuplicateEmail: false);
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password;
      debugPrint('[Auth] Starting login for: $cleanEmail');

      final data = await _api.post(
        ApiEndpoints.login,
        data: {'email': cleanEmail, 'password': cleanPassword},
      );

      String? token;
      if (data is Map<String, dynamic>) {
        if (data['token'] != null && data['token'].toString().isNotEmpty) {
          token = data['token'].toString();
          await SecureStorageService.saveSessionToken(token);
        }
        if (data['id'] != null) {
          await SecureStorageService.saveUserId(data['id'].toString());
        }
      }

      token ??= await SecureStorageService.getSessionToken();
      token ??= _api.lastExtractedToken;

      if (token != null && token.isNotEmpty) {
        await SecureStorageService.saveSessionToken(token);
      } else {
        throw ApiException('Login succeeded on server, but no session token could be established.');
      }

      await checkAuth();
      if (!state.isAuthenticated && state.error == null) {
        state = state.copyWith(error: 'Unable to load your profile. Please try again.');
      }
      return state.isAuthenticated;
    } on ApiException catch (e) {
      debugPrint('[Auth Error] Login failed: ${e.message} (status: ${e.statusCode})');
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      debugPrint('[Auth Error] Unexpected login failure: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  Future<String?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, isDuplicateEmail: false);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleServerClientId.trim().isNotEmpty
            ? _googleServerClientId.trim()
            : null,
      );

      // Clear any stale cached Google sign-in state so account selection always opens cleanly
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the Google account selection dialog
        debugPrint('[GoogleAuth] User cancelled account selection.');
        state = state.copyWith(isLoading: false, error: null);
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      final selectedEmail = account.email.trim().toLowerCase();

      debugPrint(
        '[GoogleAuth] Account selected: $selectedEmail '
        '(hasIdToken: ${idToken != null && idToken.isNotEmpty}, '
        'hasAccessToken: ${accessToken != null && accessToken.isNotEmpty})',
      );

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw ApiException(
          'Google Sign-In did not return a valid OAuth token. Please try again.',
        );
      }

      final data = await _api.post(
        ApiEndpoints.googleAuth,
        data: {
          'email': selectedEmail,
          if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
          if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
          if (account.displayName != null && account.displayName!.trim().isNotEmpty)
            'displayName': account.displayName!.trim(),
        },
      );

      String targetEmail = selectedEmail;
      bool isNewUser = false;
      if (data is Map<String, dynamic>) {
        if (data['email'] != null && data['email'].toString().isNotEmpty) {
          targetEmail = data['email'].toString().trim().toLowerCase();
        }
        isNewUser = data['isNewUser'] as bool? ?? false;
      }

      // Ensure any previous session storage and cached user are completely wiped
      await SecureStorageService.clearAll();

      // Do NOT issue or store a session token yet.
      // Full session authentication is only granted after successful 6-digit OTP verification.
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        isNewUser: isNewUser,
        user: null,
        error: null,
      );

      debugPrint('[GoogleAuth] Identity verified on backend. OTP dispatched strictly to $targetEmail.');
      return targetEmail;
    } on PlatformException catch (e) {
      debugPrint(
        '[GoogleAuth PlatformException] code=${e.code}, message=${e.message}, details=${e.details}',
      );
      final raw = '${e.code} ${e.message ?? ''} ${e.details ?? ''}';

      if (e.code == GoogleSignIn.kSignInCanceledError || raw.contains('12501')) {
        // User cancelled the sign-in picker
        state = state.copyWith(isLoading: false, error: null);
        return null;
      }

      String friendlyError;
      if (raw.contains('ApiException: 10') || raw.contains('DEVELOPER_ERROR')) {
        friendlyError =
            'Google OAuth Error 10 (DEVELOPER_ERROR): Android OAuth Client ID for package '
            '"com.roamora.app" with SHA-1 fingerprint '
            '0E:8D:FF:48:41:33:40:72:07:BE:C8:96:6F:BD:EF:A1:46:28:C1:BC '
            'is not yet registered in Google Cloud Console.';
      } else if (raw.contains('ApiException: 12500') || e.code == GoogleSignIn.kSignInFailedError) {
        friendlyError =
            'Google Sign-In failed (Error 12500): Verify that the OAuth Consent Screen has '
            'support email configured and your Gmail is added under Test Users in Google Cloud Console.';
      } else if (raw.contains('ApiException: 7') || e.code == GoogleSignIn.kNetworkError) {
        friendlyError =
            'Network error communicating with Google Play Services. Check your internet connection.';
      } else {
        friendlyError = 'Google Sign-In error (${e.code}): ${e.message ?? "Unable to complete Google authentication."}';
      }

      state = state.copyWith(isLoading: false, error: friendlyError);
      return null;
    } on ApiException catch (e) {
      debugPrint('[GoogleAuth ApiException] status=${e.statusCode}, message=${e.message}');
      final msg = e.statusCode == 404
          ? 'Backend route POST /api/v1/auth/google returned 404 on Render. Push/deploy the updated backend to Render so it can verify your Google token.'
          : e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    } catch (e) {
      debugPrint('[GoogleAuth Unexpected] $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Google Sign-In error: $e',
      );
      return null;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String birthDate,
    required String displayName,
    required String bio,
    required String city,
    required List<String> interests,
    String? gender,
    String? connectionGoal,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isDuplicateEmail: false);
    try {
      final cleanEmail = email.trim().toLowerCase();
      debugPrint('[Auth] Starting registration for: $cleanEmail');

      final data = await _api.post(
        ApiEndpoints.register,
        data: {
          'email': cleanEmail,
          'password': password,
          'birthDate': birthDate,
          'displayName': displayName.trim(),
          'bio': bio.trim(),
          'city': city.trim(),
          'interests': interests,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (connectionGoal != null && connectionGoal.isNotEmpty) 'lookingFor': connectionGoal,
        },
      );

      String? token;
      if (data is Map<String, dynamic>) {
        if (data['token'] != null && data['token'].toString().isNotEmpty) {
          token = data['token'].toString();
          await SecureStorageService.saveSessionToken(token);
        }
        if (data['id'] != null) {
          await SecureStorageService.saveUserId(data['id'].toString());
        }
      }

      token ??= await SecureStorageService.getSessionToken();
      token ??= _api.lastExtractedToken;

      if (token != null && token.isNotEmpty) {
        await SecureStorageService.saveSessionToken(token);
      }

      await checkAuth();
      state = state.copyWith(isNewUser: true);
      return state.isAuthenticated;
    } on ApiException catch (e) {
      debugPrint('[Auth Error] Registration failed: ${e.message} (status: ${e.statusCode})');
      final isDuplicate = e.statusCode == 409 ||
          e.message.toLowerCase().contains('already exists');
      state = state.copyWith(
        isLoading: false,
        error: isDuplicate
            ? 'An account with this email already exists. Redirecting you to Log In...'
            : e.message,
        isDuplicateEmail: isDuplicate,
      );
      return false;
    } catch (e) {
      debugPrint('[Auth Error] Unexpected registration failure: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final res = await _api.post(
      ApiEndpoints.otpSend,
      data: {'email': cleanEmail},
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'sent': true, 'expiresInSeconds': 60};
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      final data = await _api.post(
        ApiEndpoints.otpVerify,
        data: {
          'email': cleanEmail,
          'code': code.trim(),
        },
      );
      if (data is Map<String, dynamic> &&
          data['token'] != null &&
          data['token'].toString().isNotEmpty) {
        final token = data['token'].toString();
        await SecureStorageService.saveSessionToken(token);
      }
      await checkAuth();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadProfilePhotos(List<String> photos) async {
    if (photos.length < 2) {
      state = state.copyWith(error: 'Please select at least 2 photos.');
      return false;
    }
    try {
      try {
        await _api.post(ApiEndpoints.profilePhotos, data: {'photos': photos});
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          // Fallback to PATCH /profile if backend route is not yet deployed on remote server
          await _api.patch(
            ApiEndpoints.profile,
            data: {
              'photos': photos,
              'imageUrl': photos.first,
            },
          );
        } else {
          rethrow;
        }
      }
      await checkAuth();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    try {
      try {
        await _api.post(ApiEndpoints.onboardingComplete);
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
      await checkAuth();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<Map<String, dynamic>> startLivenessSession() async {
    final res = await _api.post(ApiEndpoints.livenessSession);
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw ApiException('Unexpected response starting face liveness session.');
  }

  Future<Map<String, dynamic>> verifyLiveness({
    required String sessionId,
    String? faceScanPayload,
    String? auditTrailImage,
  }) async {
    final res = await _api.post(
      ApiEndpoints.livenessVerify,
      data: {
        'sessionId': sessionId,
        if (faceScanPayload != null) 'faceScanPayload': faceScanPayload,
        if (auditTrailImage != null) 'auditTrailImage': auditTrailImage,
      },
    );
    await checkAuth();
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'verified': false};
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors on logout
    }
    await SecureStorageService.clearAll();
    state = AuthState(isAuthenticated: false);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _api.patch(ApiEndpoints.profile, data: data);
      await checkAuth();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> data) async {
    try {
      await _api.put(ApiEndpoints.preferences, data: data);
      await checkAuth();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
