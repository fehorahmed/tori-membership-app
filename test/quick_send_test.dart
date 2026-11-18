import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/quick_send.dart';
import 'package:tori_mfi_bank/services/beneficiary_service.dart';
import 'package:tori_mfi_bank/services/send_money_service.dart';
import 'package:tori_mfi_bank/state.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));
  test(
      'Quick Send quote passes stable recipient ID and keeps verification on backend',
      () async {
    final service = SendMoneyService(client: MockClient((request) async {
      expect(request.url.path, endsWith('/transfers/quote'));
      expect(jsonDecode(request.body)['recipient_id'], 42);
      return http.Response('{"success":true,"data":{}}', 200);
    }));
    addTearDown(service.close);
    expect(
        (await service.quote('OLD-ID', '100', 'en',
            recipientId: 42))['success'],
        true);
  });
  testWidgets(
      'Saved recipients load, nickname edits and remove require confirmation',
      (tester) async {
    var nickname = 'Family';
    var removed = false;
    final service = BeneficiaryService(client: MockClient((request) async {
      if (request.method == 'PATCH') {
        nickname = jsonDecode(request.body)['nickname'];
      }
      if (request.method == 'DELETE') removed = true;
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': removed
                  ? []
                  : [
                      {
                        'id': 1,
                        'recipient_id': 42,
                        'name': 'Real Member',
                        'nickname': nickname,
                        'member_no': 'M-42',
                        'active': true,
                        'image': null
                      }
                    ]
            }
          }),
          200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuickSendPanel(
                state: ToriState(), service: service, expanded: true))));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsOneWidget);
    await tester.longPress(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Office');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Office'), findsOneWidget);
    await tester.longPress(find.text('Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(removed, false);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(removed, true);
    expect(find.text('Office'), findsNothing);
  });
  testWidgets('Add verifies member before saving stable ID', (tester) async {
    var saved = false;
    final service = BeneficiaryService(client: MockClient((request) async {
      if (request.url.path.endsWith('/lookup')) {
        expect(jsonDecode(request.body)['recipient'], 'M-42');
        return http.Response(
            '{"success":true,"data":{"recipient_id":42,"name":"Verified Member","member_no":"M-42"}}',
            200);
      }
      if (request.method == 'POST') {
        expect(jsonDecode(request.body)['recipient_id'], 42);
        saved = true;
      }
      return http.Response('{"success":true,"data":{"items":[]}}', 200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuickSendPanel(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'M-42');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified Member'), findsOneWidget);
    expect(saved, false);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(saved, true);
  });
}
