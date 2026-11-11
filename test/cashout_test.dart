import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/cashout.dart';
import 'package:tori_mfi_bank/ui.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/services/cashout_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  test('Configured range includes both boundaries and rejects below minimum',
      () {
    expect(
        transactionAmountError('99.99', '100.00', '5000.00', false), isNotNull);
    expect(
        transactionAmountError('100.00', '100.00', '5000.00', false), isNull);
    expect(
        transactionAmountError('5000.00', '100.00', '5000.00', false), isNull);
    expect(transactionAmountError('5000.01', '100.00', '5000.00', true),
        contains('পরিমাণ'));
    expect(transactionAmountError('0.50', '0.50', '10.00', false), isNull);
  });

  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-member-token'}));

  test(
      'Ambiguous retries reuse the same financial request and never persist the PIN',
      () async {
    final keys = <String>[];
    var calls = 0;
    final service = CashoutService(client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-member-token');
      final data = jsonDecode(request.body);
      keys.add(data['idempotency_key']);
      expect(data['quote'], 'signed-quote');
      if (calls++ == 0) throw http.ClientException('Connection lost');
      return http.Response('{"success":true,"data":{"status":"Pending"}}', 201);
    }));
    addTearDown(service.close);
    final quote = {
      'quote': 'signed-quote',
      'amount': '1000.00',
      'fee': '10.00',
      'total': '1010.00'
    };
    final first = await service.create(123, quote, '763921', 'en');
    expect(first['uncertain'], true);
    final changed = await service.create(
        123, {...quote, 'quote': 'another-quote'}, '763921', 'en');
    expect(changed['uncertain'], true);
    expect(calls, 1);
    final saved = await service.pending(123);
    expect(saved!.containsKey('pin'), false);
    expect(jsonEncode(saved), isNot(contains('763921')));
    expect((await service.create(123, quote, '763921', 'en'))['success'], true);
    expect(keys[0], keys[1]);
    expect(await service.pending(123), isNull);
  });

  testWidgets(
      'Member reviews the server charge before PIN confirmation and sees pending hold',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? key;
    final service = CashoutService(client: MockClient((request) async {
      if (request.url.path.endsWith('/quote'))
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'quote': 'signed-quote',
                'branch': 'Dhaka',
                'amount': '1000.00',
                'fee': '10.00',
                'total': '1010.00'
              }
            }),
            200);
      if (request.method == 'POST') {
        final body = jsonDecode(request.body);
        expect(body['pin'], '763921');
        key = body['idempotency_key'];
        return http.Response(
            '{"success":true,"data":{"id":1,"status":"Pending"}}', 201);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'customer_id': 123,
              'enabled': true,
              'maximum_amount': '5000.00',
              'balance': '10000.00',
              'available_balance': key == null ? '10000.00' : '8990.00',
              'held_balance': key == null ? '0.00' : '1010.00',
              'requests': key == null
                  ? []
                  : [
                      {
                        'id': 1,
                        'reference': 'CO-TEST',
                        'request_key': key,
                        'branch': 'Dhaka',
                        'status': 'Pending',
                        'amount': '1000.00',
                        'fee': '10.00',
                        'total': '1010.00'
                      }
                    ],
            }
          }),
          200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CashoutPage(
                state: ToriState(),
                service: service,
                initialQr: 'tori:cashout:test'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1000.00');
    await tester.ensureVisible(find.text('Review cash-out'));
    await tester.tap(find.text('Review cash-out'));
    await tester.pumpAndSettle();
    expect(find.text('৳ 1010.00'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cashout-pin')), '763921');
    await tester.ensureVisible(find.text('Confirm cash-out'));
    await tester.tap(find.text('Confirm cash-out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(key, isNull);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(key, isNull);
    expect(find.byKey(const Key('cashout-pin')), findsOneWidget);
    await tester.tap(find.text('Confirm cash-out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('cashout-final-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('CO-TEST'), findsOneWidget);
    expect(find.text('Waiting for branch'), findsOneWidget);
    expect(find.text('Confirm cash-out'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
