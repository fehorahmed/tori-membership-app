import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/registration.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Registration explains website password, verifies OTP, then submits matching app PIN',
      (tester) async {
    final posts = <String, Map<String, dynamic>>{};
    final previous = AuthService.client;
    AuthService.client = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET')
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'branches': [
                  {'id': 1, 'name': 'Test Branch', 'code': 'TB'}
                ]
              }
            }),
            200);
      posts[path] = jsonDecode(request.body) as Map<String, dynamic>;
      if (path.endsWith('/initiate'))
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'registration_token': 'registration-secret',
                'resend_wait_seconds': 60
              }
            }),
            200);
      if (path.endsWith('/verify-otp'))
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {'verification_token': 'verified-secret'}
            }),
            200);
      return http.Response(
          jsonEncode(
              {'success': false, 'message': 'Test server declined PIN.'}),
          422);
    });
    addTearDown(() {
      AuthService.client.close();
      AuthService.client = previous;
    });
    final state = ToriState();
    await tester
        .pumpWidget(MaterialApp(home: RegistrationScreen(state: state)));
    await tester.pumpAndSettle();
    expect(
        find.textContaining(
            'This password is required to log in to the website.'),
        findsOneWidget);
    Future<void> enter(String key, String value) async {
      final finder = find.byKey(Key(key));
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
    }

    await enter('registration-name', 'Test Member');
    await enter('registration-mobile', '+8801712345678');
    await tester.ensureVisible(find.byKey(const Key('registration-branch')));
    await tester.tap(find.byKey(const Key('registration-branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TB Test Branch').last);
    await tester.pumpAndSettle();
    await enter('registration-password', 'website-pass-42');
    await enter('registration-password-confirmation', 'website-pass-42');
    await tester.ensureVisible(find.byKey(const Key('registration-consent')));
    await tester.tap(find.byKey(const Key('registration-consent')));
    await tester.ensureVisible(find.text('Send OTP'));
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    final initiated =
        posts.entries.firstWhere((e) => e.key.endsWith('/initiate')).value;
    expect(initiated['mobile_no'], '01712345678');
    expect(initiated['password'], 'website-pass-42');
    expect(initiated.containsKey('pin'), false);
    expect(state.loggedIn, false);
    await enter('registration-otp', '123456');
    await tester.ensureVisible(find.text('Verify OTP'));
    await tester.tap(find.text('Verify OTP'));
    await tester.pumpAndSettle();
    await enter('registration-pin', '067891');
    await enter('registration-pin-confirmation', '067891');
    await tester.ensureVisible(find.text('Complete Registration'));
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();
    final completed =
        posts.entries.firstWhere((e) => e.key.endsWith('/complete')).value;
    expect(completed['pin'], '067891');
    expect(completed['verification_token'], 'verified-secret');
    expect(completed['registration_token'], 'registration-secret');
    expect(completed.containsKey('password'), false);
    expect(find.text('Test server declined PIN.'), findsOneWidget);
    expect(state.loggedIn, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Registration does not submit without consent and matching website passwords',
      (tester) async {
    var writes = 0;
    final previous = AuthService.client;
    AuthService.client = MockClient((request) async {
      if (request.method != 'GET') writes++;
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'branches': [
                {'id': 1, 'name': 'Test', 'code': 'T'}
              ]
            }
          }),
          200);
    });
    addTearDown(() {
      AuthService.client.close();
      AuthService.client = previous;
    });
    await tester
        .pumpWidget(MaterialApp(home: RegistrationScreen(state: ToriState())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send OTP'));
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
