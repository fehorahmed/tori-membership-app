import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/member_card.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/services/profile_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));

  testWidgets(
      'Unissued card shows an empty state without invented card details',
      (tester) async {
    final service = ProfileService(client: MockClient((request) async {
      expect(request.url.path, '/api/membership/v1/card');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response('{"success":true,"data":{"card":null}}', 200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MemberCardPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    expect(find.text('No card issued yet'), findsOneWidget);
    expect(find.text('Show card number'), findsNothing);
  });

  testWidgets(
      'Issued card uses real data, masks number and fits a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = ProfileService(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'card': {
                  'card_number': 'TORI-C-12345',
                  'holder_name': 'Actual Member',
                  'member_no': 'MEM-001',
                  'status': 'Active',
                  'branch': 'Dhaka',
                  'issued_at': '2026-11-10',
                  'fee': 100,
                  'fee_status': 'Received',
                  'printed_at': null,
                }
              }
            }),
            200)));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MemberCardPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    expect(find.text('TORI-C-12345'), findsNothing);
    expect(find.text('VISA'), findsNothing);
    expect(find.text('CVV'), findsNothing);
    expect(find.text('Actual Member'), findsWidgets);
    await tester.ensureVisible(find.text('Show card number'));
    await tester.tap(find.text('Show card number'));
    await tester.pumpAndSettle();
    expect(find.text('TORI-C-12345'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
