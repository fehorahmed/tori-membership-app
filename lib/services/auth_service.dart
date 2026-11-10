import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Load from .env with: flutter run --dart-define-from-file=.env
  // An explicit --dart-define=BASE_URL=... takes precedence over the file.
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  static String get baseUrl {
    final value = _envBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.isEmpty) {
      throw StateError(
        'BASE_URL is missing. Run Flutter with --dart-define-from-file=.env',
      );
    }
    return value;
  }

  static String get membershipAuthUrl => '$baseUrl/membership/v1/auth';
  static String get membershipUrl => '$baseUrl/membership/v1';

  static const String tokenKey = 'customer_auth_token';
  static const String profileKey = 'customer_cached_profile';
}

class AuthService {
  static http.Client client = http.Client();
  static const deviceIdKey = 'membership_installation_id';

  static String normalizeMobile(String raw) {
    final mobile = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobile.startsWith('880')) return '0${mobile.substring(3)}';
    if (mobile.length == 10 && mobile.startsWith('1')) return '0$mobile';
    return mobile;
  }

  static String trustedKey(String mobile) =>
      'membership_device_${normalizeMobile(mobile)}';

  static Future<Map<String, dynamic>> device(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(deviceIdKey);
    if (id == null) {
      final random = Random.secure();
      id = base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)))
          .replaceAll('=', '');
      await prefs.setString(deviceIdKey, id);
    }
    return {
      'device_id': id,
      'device_token': prefs.getString(trustedKey(mobile)),
      'device_name':
          kIsWeb ? 'TORI Browser' : 'TORI ${defaultTargetPlatform.name}',
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    };
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body, String language) async {
    try {
      final response = await client
          .post(Uri.parse('${ApiConfig.membershipAuthUrl}/$endpoint'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Accept-Language': language
              },
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {
        ...data,
        'success': false,
        'message': data['message'] ??
            (language == 'bn'
                ? 'লগইন করা যায়নি। আবার চেষ্টা করুন।'
                : 'Unable to sign in. Please try again.')
      };
    } catch (_) {
      return {
        'success': false,
        'message': language == 'bn'
            ? 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি। আবার চেষ্টা করুন।'
            : 'Unable to connect to the server. Please try again.'
      };
    }
  }

  static Future<void> saveLogin(
      Map<String, dynamic> result, String mobile) async {
    if (result['success'] != true) return;
    final prefs = await SharedPreferences.getInstance();
    final data = result['data'];
    if (data['token'] != null)
      await prefs.setString(ApiConfig.tokenKey, data['token']);
    if (data['device_token'] != null)
      await prefs.setString(trustedKey(mobile), data['device_token']);
  }

  static Future<Map<String, dynamic>> initiateLogin(String rawMobile,
      {String language = 'en', bool resetPin = false}) async {
    return post(
        'initiate',
        {
          ...await device(rawMobile),
          'mobile_no': normalizeMobile(rawMobile),
          'reset_pin': resetPin
        },
        language);
  }

  static Future<Map<String, dynamic>> verifyOtp(
      {required String rawMobile,
      required String otp,
      String language = 'en'}) async {
    return post(
        'verify-otp',
        {
          ...await device(rawMobile),
          'mobile_no': normalizeMobile(rawMobile),
          'otp': otp
        },
        language);
  }

  static Future<Map<String, dynamic>> loginWithPin(
      {required String rawMobile,
      required String pin,
      String? verificationToken,
      String? deviceName,
      String language = 'en'}) async {
    final result = await post(
        'login-pin',
        {
          ...await device(rawMobile),
          'mobile_no': normalizeMobile(rawMobile),
          'pin': pin,
          if (verificationToken != null)
            'verification_token': verificationToken,
          if (deviceName != null) 'device_name': deviceName
        },
        language);
    await saveLogin(result, rawMobile);
    return result;
  }

  static Future<Map<String, dynamic>> setPin(
      {required String rawMobile,
      required String verificationToken,
      required String pin,
      required String pinConfirmation,
      String? deviceName,
      String language = 'en'}) async {
    final result = await post(
        'set-pin',
        {
          ...await device(rawMobile),
          'verification_token': verificationToken,
          'pin': pin,
          'pin_confirmation': pinConfirmation,
          if (deviceName != null) 'device_name': deviceName
        },
        language);
    await saveLogin(result, rawMobile);
    return result;
  }
}
