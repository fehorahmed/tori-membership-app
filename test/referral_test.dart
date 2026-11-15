import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/referrals.dart';
import 'package:tori_mfi_bank/services/referral_service.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));

  test(
      'Uncertain redemption reuses identical points, rate and key without persisting PIN',
      () async {
    final requests = <Map<String, dynamic>>[];
    final service = ReferralService(client: MockClient((r) async {
      expect(r.url.path, '/api/membership/v1/referrals/redeem');
      expect(r.headers['Authorization'], 'Bearer test-token');
      expect(r.headers['Accept-Language'], 'bn');
      requests.add(Map<String, dynamic>.from(jsonDecode(r.body)));
      if (requests.length == 1) throw http.ClientException('Lost response');
      return http.Response('{"success":true,"data":{"amount":"60.00"}}', 201);
    }));
    addTearDown(service.close);
    expect((await service.redeem(9, 2, '30.00', '763921', 'bn'))['uncertain'],
        true);
    expect(jsonEncode(await service.pending(9)), isNot(contains('763921')));
    expect(await service.pending(10), isNull);
    expect((await service.redeem(9, 999, '99.00', '763921', 'bn'))['success'],
        true);
    expect(requests[0], requests[1]);
    expect(await service.pending(9), isNull);
  });

  test(
      'Definite validation failure clears request so member can review current rate',
      () async {
    final service = ReferralService(
        client: MockClient((_) async =>
            http.Response('{"message":"Point value changed."}', 422)));
    addTearDown(service.close);
    final result = await service.redeem(9, 1, '30.00', '763921', 'en');
    expect(result['success'], false);
    expect(result['message'], 'Point value changed.');
    expect(await service.pending(9), isNull);
  });

  testWidgets('Member reviews points and confirms before savings redemption',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var posts = 0;
    final service = ReferralService(client: MockClient((r) async {
      if (r.method == 'POST') {
        posts++;
        expect(jsonDecode(r.body)['points'], 1);
        return http.Response('{"success":true,"data":{"amount":"30.00"}}', 201);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'customer_id': 9,
              'enabled': true,
              'points': posts == 0 ? 2 : 1,
              'point_value': '30.00',
              'redeemable_amount': '60.00',
              'referral_count': 1,
              'rewarded_count': 1,
              'milestones': {
                'enabled': true,
                'tiers': [
                  {
                    'id': 'tier-1',
                    'threshold': 100,
                    'percentage': '25.00',
                    'enabled': true
                  }
                ],
                'bonuses': []
              },
              'redemptions': []
            }
          }),
          200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ReferralPointsPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    expect(find.text('Available points: 2'), findsOneWidget);
    expect(find.text('Progress: 2/100'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.enterText(find.byType(TextField).at(1), '763921');
    await tester.tap(find.text('Redeem to savings'));
    await tester.pumpAndSettle();
    expect(posts, 0);
    expect(find.text('Redeem 1 points for Tk 30.00 into your savings account?'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(posts, 0);
    await tester.tap(find.text('Redeem to savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('Tk 30.00 credited to savings.'), findsOneWidget);
    expect(find.text('Available points: 1'), findsOneWidget);
    expect(find.text('Progress: 1/100'), findsOneWidget);
  });
  testWidgets(
      'Milestone check posts only a collection request and shows cash paid',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var posts = 0;
    final service = ReferralService(client: MockClient((r) async {
      if (r.method == 'POST') {
        expect(r.url.path, '/api/membership/v1/referrals/milestones/collect');
        expect(jsonDecode(r.body), isEmpty);
        posts++;
        return http.Response('{"success":true}', 200);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'customer_id': 9,
              'enabled': true,
              'points': 100,
              'point_value': '30.00',
              'redeemable_amount': '3000.00',
              'referral_count': 50,
              'rewarded_count': 50,
              'redemptions': [],
              'milestones': {
                'enabled': true,
                'tiers': [
                  {
                    'id': 'tier-1',
                    'threshold': 100,
                    'percentage': '25.00',
                    'enabled': true
                  }
                ],
                'bonuses': posts == 0
                    ? []
                    : [
                        {
                          'tier_id': 'tier-1',
                          'threshold': 100,
                          'amount': '750.00',
                          'paid_at': '2026-11-15 14:00:00'
                        }
                      ]
              }
            }
          }),
          200);
    }));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ReferralPointsPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check / collect milestone bonus'));
    await tester.tap(find.text('Check / collect milestone bonus'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('Available points: 100'), findsOneWidget);
    expect(find.text('100 point milestone · Tk 750.00'), findsOneWidget);
    expect(find.text('Paid to savings: 2026-11-15 14:00:00'), findsOneWidget);
  });
}
