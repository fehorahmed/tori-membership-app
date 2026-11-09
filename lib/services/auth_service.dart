import 'dart:convert';
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
  /// Step 1: Submit mobile number to initiate login and send OTP
  static Future<Map<String, dynamic>> initiateLogin(String rawMobile) async {
    final cleanMobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.membershipAuthUrl}/initiate'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'mobile_no': cleanMobile}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'মোবাইল নম্বর যাচাই ব্যর্থ হয়েছে।',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি ($e)',
      };
    }
  }

  /// Step 2: Verify 6-digit OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String rawMobile,
    required String otp,
  }) async {
    final cleanMobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.membershipAuthUrl}/verify-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'mobile_no': cleanMobile, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'ভুল বা মেয়াদোত্তীর্ণ ওটিপি।',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি ($e)',
      };
    }
  }

  /// Step 3 (A): Login with 6-digit PIN
  static Future<Map<String, dynamic>> loginWithPin({
    required String rawMobile,
    required String pin,
    required String verificationToken,
    String? deviceName,
  }) async {
    final cleanMobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.membershipAuthUrl}/login-pin'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'mobile_no': cleanMobile,
          'pin': pin,
          'verification_token': verificationToken,
          'device_name': deviceName ?? 'Flutter Mobile App',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data']['token'] != null) {
          await prefs.setString(ApiConfig.tokenKey, data['data']['token']);
        }
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'ভুল পিন দিয়েছেন।',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি ($e)',
      };
    }
  }

  /// Step 3 (B): Set / Reset 6-digit PIN
  static Future<Map<String, dynamic>> setPin({
    required String verificationToken,
    required String pin,
    required String pinConfirmation,
    String? deviceName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.membershipAuthUrl}/set-pin'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'verification_token': verificationToken,
          'pin': pin,
          'pin_confirmation': pinConfirmation,
          'device_name': deviceName ?? 'Flutter Mobile App',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data']['token'] != null) {
          await prefs.setString(ApiConfig.tokenKey, data['data']['token']);
        }
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'পিন সংরক্ষণ ব্যর্থ হয়েছে।',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি ($e)',
      };
    }
  }
}

