import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/services/biometric_service.dart';

class FakeBiometrics extends LocalAuthPlatform {
  bool available = true, accepted = true;
  @override
  Future<bool> deviceSupportsBiometrics() async => available;
  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async =>
      available ? [BiometricType.strong] : [];
  @override
  Future<bool> authenticate(
          {required String localizedReason,
          required Iterable<AuthMessages> authMessages,
          AuthenticationOptions options =
              const AuthenticationOptions()}) async =>
      accepted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBiometrics biometric;
  final original = LocalAuthPlatform.instance;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({ApiConfig.tokenKey: 'session'});
    FlutterSecureStorage.setMockInitialValues({});
    biometric = FakeBiometrics();
    LocalAuthPlatform.instance = biometric;
    AuthService.client =
        MockClient((_) async => throw StateError('No network call expected'));
  });
  tearDown(() {
    LocalAuthPlatform.instance = original;
    debugDefaultTargetPlatformOverride = null;
    AuthService.client.close();
  });
  test(
      'Unavailable device and cancelled fingerprint never enable backend credentials',
      () async {
    biometric.available = false;
    expect(await BiometricService.supported(), false);
    expect(
        (await BiometricService.login('01712345678', 'en'))['success'], false);
    biometric.available = true;
    biometric.accepted = false;
    await expectLater(
        BiometricService.configure('01712345678', true, pin: '123456'),
        throwsException);
    expect(await BiometricService.enabled('01712345678'), false);
  });
  test(
      'Enable saves account scoped credential, login saves session, disable removes credential',
      () async {
    AuthService.client = MockClient((request) async {
      final body = jsonDecode(request.body);
      if (request.url.path.endsWith('toggle-biometric')) {
        expect(request.headers['Authorization'], 'Bearer session');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {'biometric_token': body['enable'] ? 'credential' : null}
            }),
            200);
      }
      expect(body['biometric_token'], 'credential');
      expect(body['device_id'], isNotEmpty);
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'new-session'}
          }),
          200);
    });
    await BiometricService.configure('01712345678', true, pin: '123456');
    expect(await BiometricService.enabled('01712345678'), true);
    expect(await BiometricService.enabled('01912345678'), false);
    expect(
        (await BiometricService.login('01712345678', 'en'))['success'], true);
    expect(
        (await SharedPreferences.getInstance()).getString(ApiConfig.tokenKey),
        'new-session');
    AuthService.client = MockClient(
        (_) async => http.Response('{"success":true,"data":{}}', 200));
    await BiometricService.configure('01712345678', false);
    expect(await BiometricService.enabled('01712345678'), false);
    expect(
        await BiometricService.storage
            .read(key: BiometricService.key('01712345678')),
        isNull);
  });
}
