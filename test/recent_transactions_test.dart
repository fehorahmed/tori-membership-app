import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/state.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/services/dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));
  test(
      'Dashboard replaces demo transactions with member rows and clears on logout',
      () async {
    final old = DashboardService.client;
    DashboardService.client = MockClient((r) async => http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': true,
          'data': {
            'recent_transactions': [
              {
                'id': 'transfer-1',
                'reference': 'SM-1',
                'title_en': 'Sent to Test',
                'title_bn': 'টাকা পাঠিয়েছেন',
                'category_en': 'Send Money',
                'category_bn': 'সেন্ড মানি',
                'amount': '1010.00',
                'net_amount': '1000.00',
                'fee': '10.00',
                'is_credit': false,
                'status_en': 'Completed',
                'status_bn': 'সম্পন্ন',
                'occurred_at': '2026-11-10T10:00:00+06:00'
              }
            ]
          }
        })),
        200,
        headers: {'Content-Type': 'application/json; charset=utf-8'}));
    addTearDown(() {
      DashboardService.client.close();
      DashboardService.client = old;
    });
    final state = ToriState();
    expect(state.transactions, isEmpty);
    final response = await DashboardService.fetchDashboardData();
    expect(response['success'], true, reason: response.toString());
    await state.loadDashboardData();
    expect(state.transactions, hasLength(1));
    final row = state.transactions.single;
    expect(row.txnId, 'SM-1');
    expect(row.amount, 1010);
    expect(row.netAmount, 1000);
    expect(row.fee, 10);
    expect(row.occurredAt, isNotNull);
    expect(row.copyWith().fee, 10);
    state.logout();
    expect(state.transactions, isEmpty);
  });
  test('Failed dashboard never inserts demo history', () async {
    final old = DashboardService.client;
    DashboardService.client =
        MockClient((r) async => http.Response('{"success":false}', 500));
    addTearDown(() {
      DashboardService.client.close();
      DashboardService.client = old;
    });
    final state = ToriState();
    await state.loadDashboardData();
    expect(state.transactions, isEmpty);
  });
}
