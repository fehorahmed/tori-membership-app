import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/send_money.dart';
import 'package:tori_mfi_bank/services/send_money_service.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));
  test(
      'Ambiguous transfer retries reuse key and never store PIN or share cashout keys',
      () async {
    final keys = <String>[];
    var calls = 0;
    final service = SendMoneyService(client: MockClient((r) async {
      expect(r.url.path.endsWith('/transfers'), true);
      final body = jsonDecode(r.body);
      keys.add(body['idempotency_key']);
      if (calls++ == 0) throw http.ClientException('Lost response');
      return http.Response('{"success":true,"data":{"reference":"SM-1"}}', 201);
    }));
    addTearDown(service.close);
    final q = {
      'quote': 'signed',
      'amount': '100.00',
      'fee': '1.00',
      'total': '101.00'
    };
    expect((await service.create(1, q, '763921', 'en'))['uncertain'], true);
    final saved = await service.pending(1);
    expect(jsonEncode(saved), isNot(contains('763921')));
    expect(
        (await SharedPreferences.getInstance()).getString('cashout_pending_1'),
        isNull);
    expect((await service.create(1, q, '763921', 'en'))['success'], true);
    expect(keys[0], keys[1]);
    expect(await service.pending(1), isNull);
  });
  testWidgets('Review recipient and fees, cancel confirmation, then send once',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sends = 0;
    final service = SendMoneyService(client: MockClient((r) async {
      if (r.url.path.endsWith('/quote'))
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'quote': 'signed',
                'recipient_name': 'Receiver Test',
                'recipient_member_no': 'M-2',
                'amount': '100.00',
                'fee': '1.00',
                'total': '101.00'
              }
            }),
            200);
      if (r.method == 'POST') {
        sends++;
        return http.Response(
            '{"success":true,"data":{"reference":"SM-TEST"}}', 201);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'customer_id': 1,
              'enabled': true,
              'available_balance': sends == 0 ? '1000.00' : '899.00',
              'transfers': []
            }
          }),
          200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SendMoneyPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '01712345678');
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.tap(find.text('Review transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Receiver Test'), findsOneWidget);
    expect(find.text('৳ 101.00'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('send-money-pin')), '763921');
    await tester.ensureVisible(find.text('Confirm transfer'));
    await tester.tap(find.text('Confirm transfer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(sends, 0);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(sends, 0);
    await tester.tap(find.text('Confirm transfer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('send-money-final')));
    await tester.pumpAndSettle();
    expect(sends, 1);
    expect(find.textContaining('SM-TEST'), findsOneWidget);
    expect(find.byKey(const Key('send-money-pin')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
