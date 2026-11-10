import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/auth.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    AuthService.client.close();
    AuthService.client = http.Client();
  });

  test(
      'Installation ID persists and device proof is scoped to the normalized phone',
      () async {
    final first = await AuthService.device('1755892401');
    final second = await AuthService.device('+8801755892401');
    expect(first['device_id'], second['device_id']);
    await AuthService.saveLogin({
      'success': true,
      'data': {'token': 'access', 'device_token': 'proof'}
    }, '1755892401');
    expect((await AuthService.device('01755892401'))['device_token'], 'proof');
    expect((await AuthService.device('01900000999'))['device_token'], isNull);
  });

  test(
      'Remembered login sends device proof and preserves it when server returns no new proof',
      () async {
    await AuthService.saveLogin({
      'success': true,
      'data': {'device_token': 'proof'}
    }, '01755892401');
    AuthService.client = MockClient((request) async {
      final body = jsonDecode(request.body);
      expect(body['device_token'], 'proof');
      expect(body['verification_token'], isNull);
      expect(body['mobile_no'], '01755892401');
      return http.Response(
          '{"success":true,"data":{"token":"new-access","device_token":null}}',
          200);
    });
    expect(
        (await AuthService.loginWithPin(
            rawMobile: '1755892401', pin: '763921'))['success'],
        true);
    expect((await AuthService.device('01755892401'))['device_token'], 'proof');
  });

  testWidgets(
      'Remembered device goes straight to PIN and incorrect PIN never logs in locally',
      (tester) async {
    final state = ToriState();
    AuthService.client = MockClient((request) async {
      if (request.url.path.endsWith('/initiate')) {
        return http.Response(
            '{"success":true,"data":{"otp_required":false,"has_pin":true}}',
            200);
      }
      return http.Response('{"success":false,"message":"Incorrect PIN."}', 401);
    });
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen(state: state)));
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('SECURITY PIN'), findsOneWidget);
    expect(find.byKey(const Key('otp-input')), findsNothing);
    await tester.enterText(find.byKey(const Key('pin-input')), '000000');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(state.loggedIn, false);
  });
}
