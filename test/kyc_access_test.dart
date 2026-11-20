import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/main.dart';
import 'package:tori_mfi_bank/state.dart';
import 'package:tori_mfi_bank/profile_setup.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/send_money.dart';
import 'package:tori_mfi_bank/cashout.dart';
import 'package:tori_mfi_bank/services/send_money_service.dart';
import 'package:tori_mfi_bank/services/cashout_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final status in ['Not submitted', 'Rejected', 'Pending', 'Verified']) {
    testWidgets('Login KYC reminder: $status', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = ToriState()..loggedIn = true;
      state.applyMemberProfile({
        'kyc': {'status': status, 'reviewer_message': 'Clear photo required'}
      });
      await tester.pumpWidget(ToriBankApp(state: state, monitorNetwork: false));
      await tester.pumpAndSettle();
      final expected = !['Pending', 'Verified'].contains(status);
      expect(find.text('Complete your KYC'),
          expected ? findsOneWidget : findsNothing);
      if (expected) {
        if (status == 'Rejected')
          expect(find.textContaining('Clear photo required'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        state.changed();
        await tester.pumpAndSettle();
        expect(find.text('Complete your KYC'), findsNothing);
        state.logout();
        await tester.pumpAndSettle();
        state.loggedIn = true;
        state.applyMemberProfile({
          'kyc': {'status': status}
        });
        await tester.pumpAndSettle();
        expect(find.text('Complete your KYC'), findsOneWidget);
        if (status == 'Not submitted') {
          await tester.tap(find.text('Submit KYC'));
          await tester.pumpAndSettle();
          expect(find.byType(KycSetupPage), findsOneWidget);
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Unapproved KYC blocks transfer and cashout forms',
      (tester) async {
    SharedPreferences.setMockInitialValues({ApiConfig.tokenKey: 'test-token'});
    final state = ToriState();
    final client = MockClient((request) async => http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'customer_id': 1,
            'enabled': true,
            'kyc_approved': false,
            'kyc_status': 'Pending',
            'transfers': [],
            'requests': []
          }
        }),
        200));
    final send = SendMoneyService(client: client);
    final cash = CashoutService(client: client);
    for (final page in [
      SendMoneyPage(state: state, service: send),
      CashoutPage(state: state, service: cash)
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
      await tester.pumpAndSettle();
      expect(find.text('Approved KYC is required to send money or cash out.'),
          findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Submit KYC'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
