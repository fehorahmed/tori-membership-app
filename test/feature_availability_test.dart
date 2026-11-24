import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tori_mfi_bank/dashboard.dart';
import 'package:tori_mfi_bank/payments.dart';
import 'package:tori_mfi_bank/profile.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  testWidgets('Agents see Member Cash-in instead of Send Money',
      (tester) async {
    final state = ToriState()
      ..agent = {'id': 1, 'code': 'AG-1', 'status': 'Active'};
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HomeScreen(state: state))));
    final tiles =
        tester.widgetList<ServiceTile>(find.byType(ServiceTile)).toList();
    expect(tiles.first.label, 'Member Cash-in');
    expect(tiles.map((t) => t.label), isNot(contains('Send Money')));
    expect(tiles.map((t) => t.label), isNot(contains('Agent Cash-out')));
    expect(tiles.length, 7);
    state.logout();
    expect(state.isAgent, false);
  });
  testWidgets('Home displays eight connected service cards including FDR',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HomeScreen(state: ToriState()))));
    final tiles =
        tester.widgetList<ServiceTile>(find.byType(ServiceTile)).toList();
    expect(tiles.first.enabled, true);
    expect(tiles[1].enabled, true);
    expect(tiles[1].label, 'Branch Cash-out');
    expect(tiles[2].enabled, true);
    expect(tiles.length, 8);
    expect(tiles.every((tile) => tile.enabled), true);
    expect(tiles.map((tile) => tile.label),
        containsAll(['My Card', 'Referral Points', 'Statement']));
  });
  testWidgets(
      'Profile keeps backend profile and card active, disables local-only options',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ProfileScreen(state: ToriState()))));
    InkWell row(String label) => tester.widget<InkWell>(find
        .ancestor(of: find.text(label), matching: find.byType(InkWell))
        .first);
    expect(row('My Profile').onTap, isNotNull);
    expect(row('My Card').onTap, isNotNull);
    expect(row('Nominee Information').onTap, isNull);
    expect(row('Security & Access').onTap, isNull);
    expect(row('Help & Support').onTap, isNull);
  });
  testWidgets(
      'Payments disables bill and external channels but keeps Send Money',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PaymentsScreen(state: ToriState()))));
    InkWell row(String label) => tester.widget<InkWell>(find
        .ancestor(of: find.text(label), matching: find.byType(InkWell))
        .first);
    expect(row('Pay Bills').onTap, isNull);
    expect(row('bKash / Nagad').onTap, isNull);
    expect(row('All Banks').onTap, isNull);
    expect(row('Send Money').onTap, isNotNull);
    expect(
        find.ancestor(
            of: find.text('MFI Loan Pay'),
            matching: find.byWidgetPredicate(
                (widget) => widget is AbsorbPointer && widget.absorbing)),
        findsOneWidget);
    expect(
        find.ancestor(
            of: find.text('Merchant Pay'),
            matching: find.byWidgetPredicate(
                (widget) => widget is AbsorbPointer && widget.absorbing)),
        findsOneWidget);
  });
}
