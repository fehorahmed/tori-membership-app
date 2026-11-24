import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/fdr.dart';
import 'package:tori_mfi_bank/services/fdr_service.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'fixture-session'}));
  test('Financial validation errors are visible and do not appear as success',
      () async {
    final api = FdrService(client: MockClient((r) async {
      expect(r.headers['Authorization'], 'Bearer fixture-session');
      return http.Response(
          '{"message":"Invalid","errors":{"fdr":["Approved KYC required"]}}',
          422);
    }));
    final result = await api.request('/open', body: {'amount': '1000'});
    expect(result['success'], false);
    expect(result['message'], 'Approved KYC required');
    api.close();
  });
  testWidgets(
      'FDR screen uses real scheme and account data, blocks opening without KYC',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FdrService(
        client: MockClient((r) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'kyc_approved': false,
                'available_balance': '5000.00',
                'accounts': [],
                'schemes': [
                  {
                    'id': 1,
                    'name': 'Test Scheme',
                    'duration': 12,
                    'interest_rate': '12.00',
                    'min_amount': '1000.00',
                    'max_amount': null,
                    'penalty_rate': '1.00'
                  }
                ],
                'nominees': [],
                'frequencies': ['Monthly', 'At Maturity']
              }
            }),
            200)));
    await tester.pumpWidget(
        MaterialApp(home: FdrPage(state: ToriState(), service: api)));
    await tester.pumpAndSettle();
    expect(find.text('Test Scheme'), findsOneWidget);
    expect(find.text('No FDR account yet.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Open using savings'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
  testWidgets(
      'Preview comes before PIN and savings payment; opening retries use the same key',
      (tester) async {
    final keys = <String>[];
    final api = FdrService(client: MockClient((r) async {
      final body = jsonDecode(r.body);
      if (r.url.path.endsWith('/quote'))
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'principal': '1000.00',
                'term_interest': '120.00',
                'total_term_value': '1120.00',
                'opening_date': '2026-01-01',
                'maturity_date': '2027-01-01',
                'terms': 'No premature interest',
                'terms_hash': 'a' * 64
              }
            }),
            200);
      expect(body['pin'], '123456');
      expect(body['frequency'], 'At Maturity');
      expect(body['auto_renew'], false);
      keys.add(body['idempotency_key']);
      return http.Response(
          '{"success":false,"message":"Retry after network issue"}', 503);
    }));
    await tester.pumpWidget(MaterialApp(
        home: FdrOpenPage(api: api, scheme: {
      'id': 1,
      'name': 'Test Scheme',
      'interest_rate': 12,
      'duration': 12
    }, nominees: const [], frequencies: const [
      'Monthly',
      'At Maturity'
    ])));
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .onChanged,
        isNull);
    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text('Review FDR'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('Pay from savings & activate'));
      await tester.tap(find.text('Pay from savings & activate'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    }
    expect(keys.length, 2);
    expect(keys.first, keys.last);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
}
