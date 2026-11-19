import 'dart:async';
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
  setUp(() => SharedPreferences.setMockInitialValues({ApiConfig.tokenKey: 'test-token'}));
  void response(Object? balance) {
    final previous = DashboardService.client;
    DashboardService.client = MockClient((_) async => http.Response(jsonEncode({'success': true, 'data': {
      'summary': {'savings_balance': balance}, 'recent_transactions': []}}), 200));
    addTearDown(() { DashboardService.client.close(); DashboardService.client = previous; });
  }
  test('New member state has no demo balance or financial accounts', () {
    final state = ToriState();
    expect(state.balance, 0);
    expect(state.accounts, isEmpty);
    expect(state.assets, 0);
    expect(state.dashboardBalanceLoaded, false);
  });
  for (final balance in [0, '0.00', '125.50']) {
    test('Server balance $balance replaces local values including zero', () async {
      response(balance);
      final state = ToriState()..balance = 99;
      await state.loadDashboardData();
      expect(state.balance, double.parse('$balance'));
      expect(state.dashboardBalanceLoaded, true);
      expect(state.dashboardError, isNull);
      state.logout();
      expect(state.balance, 0);
      expect(state.dashboardBalanceLoaded, false);
    });
  }
  test('Invalid balance is unavailable and never falls back to demo money', () async {
    response(null);
    final state = ToriState();
    await state.loadDashboardData();
    expect(state.balance, 0);
    expect(state.dashboardBalanceLoaded, false);
    expect(state.dashboardError, isNotNull);
  });
  test('Late response cannot restore previous member balance after logout', () async {
    final previous = DashboardService.client;
    final result = Completer<http.Response>();
    final started = Completer<void>();
    DashboardService.client = MockClient((_) { started.complete(); return result.future; });
    addTearDown(() { DashboardService.client.close(); DashboardService.client = previous; });
    final state = ToriState();
    final load = state.loadDashboardData();
    await started.future;
    state.logout();
    result.complete(http.Response('{"success":true,"data":{"summary":{"savings_balance":5000}}}', 200));
    await load;
    expect(state.balance, 0);
    expect(state.dashboardBalanceLoaded, false);
  });
}
