import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String _keySessionToken = 'roamora_session_token';
  static const String _keyUserId = 'roamora_user_id';
  static const String _keyUserEmail = 'roamora_user_email';
  static const String _keyBaseUrl = 'roamora_base_url';

  // Session Token
  static Future<void> saveSessionToken(String token) async {
    try {
      await _storage
          .write(key: _keySessionToken, value: token)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[SecureStorage Error] saveSessionToken failed: $e');
    }
  }

  static Future<String?> getSessionToken() async {
    try {
      return await _storage
          .read(key: _keySessionToken)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Warning] getSessionToken failed or timed out: $e');
      return null;
    }
  }

  static Future<void> clearSessionToken() async {
    try {
      await _storage
          .delete(key: _keySessionToken)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Warning] clearSessionToken failed: $e');
    }
  }

  // User ID
  static Future<void> saveUserId(String id) async {
    try {
      await _storage
          .write(key: _keyUserId, value: id)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[SecureStorage Error] saveUserId failed: $e');
    }
  }

  static Future<String?> getUserId() async {
    try {
      return await _storage
          .read(key: _keyUserId)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Warning] getUserId failed: $e');
      return null;
    }
  }

  // User Email
  static Future<void> saveUserEmail(String email) async {
    try {
      await _storage
          .write(key: _keyUserEmail, value: email)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[SecureStorage Error] saveUserEmail failed: $e');
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      return await _storage
          .read(key: _keyUserEmail)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Warning] getUserEmail failed: $e');
      return null;
    }
  }

  // Base URL override for flexible testing
  static Future<void> saveBaseUrl(String url) async {
    try {
      await _storage
          .write(key: _keyBaseUrl, value: url)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Error] saveBaseUrl failed: $e');
    }
  }

  static Future<String?> getBaseUrl() async {
    try {
      return await _storage
          .read(key: _keyBaseUrl)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SecureStorage Warning] getBaseUrl failed: $e');
      return null;
    }
  }

  // Clear all credentials
  static Future<void> clearAll() async {
    try {
      await _storage
          .deleteAll()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[SecureStorage Warning] clearAll failed: $e');
    }
  }
}

