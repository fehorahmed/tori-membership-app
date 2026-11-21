import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class BiometricService {
  static const storage = FlutterSecureStorage(
      aOptions: AndroidOptions.biometric(
    enforceBiometrics: true,
    requireBiometricsPerOperation: true,
    biometricType: AndroidBiometricType.strongBiometricOnly,
    storageNamespace: 'tori_biometric_credentials',
  ));
  static final auth = LocalAuthentication();
  static String key(String mobile) =>
      'biometric_${AuthService.normalizeMobile(mobile)}';
  static Future<bool> supported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await auth.canCheckBiometrics &&
          (await auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enabled(String mobile) async {
    if (!await supported()) return false;
    return (await SharedPreferences.getInstance()).getBool(key(mobile)) ??
        false;
  }

  static Future<bool> verify() async => await auth.authenticate(
      localizedReason: 'Verify your fingerprint to access Tori Member',
      biometricOnly: true);
  static Future<void> configure(String mobile, bool enable,
      {String? pin}) async {
    if (enable && (!await supported() || !await verify()))
      throw Exception('Fingerprint verification was cancelled or unavailable.');
    final response = await AuthService.client
        .post(Uri.parse('${ApiConfig.membershipAuthUrl}/toggle-biometric'),
            headers: {
              ...await ProfileService.headers(),
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              ...await AuthService.device(mobile),
              'enable': enable,
              if (enable) 'pin': pin
            }))
        .timeout(const Duration(seconds: 30));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true)
      throw Exception(data['errors']?['pin']?[0] ??
          data['message'] ??
          'Unable to update fingerprint login.');
    if (enable) {
      await storage.write(
          key: key(mobile), value: data['data']['biometric_token']);
    } else {
      await storage.delete(key: key(mobile));
    }
    await (await SharedPreferences.getInstance()).setBool(key(mobile), enable);
  }

  static Future<void> forget(String mobile) async {
    await storage.delete(key: key(mobile));
    await (await SharedPreferences.getInstance()).remove(key(mobile));
  }

  static Future<Map<String, dynamic>> login(
      String mobile, String language) async {
    try {
      if (!await enabled(mobile))
        throw Exception(
            'Enable fingerprint login in profile settings after signing in.');
      final credential = await storage.read(key: key(mobile));
      if (credential == null) {
        await forget(mobile);
        throw Exception(
            'Fingerprint credential expired. Sign in with PIN and enable it again in Settings.');
      }
      final result = await AuthService.post(
          'login-biometric',
          {
            ...await AuthService.device(mobile),
            'mobile_no': AuthService.normalizeMobile(mobile),
            'biometric_token': credential
          },
          language);
      await AuthService.saveLogin(result, mobile);
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', '')
      };
    }
  }
}
