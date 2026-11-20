import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tori_mfi_bank/dashboard.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  for (final bengali in [false, true]) {
    testWidgets('Daily cash flow uses real totals on narrow mobile bn=$bengali',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = ToriState()..bengali = bengali;
      state.cashFlows = {
        for (final period in ['day', 'week', 'month', 'year'])
          period: {
            'labels': ['00', '04', '08', '12', '16', '20'],
            'inflow': [0, 0, 100.25, 0, 0, 0],
            'outflow': [0, 0, 0, 25.5, 0, 0],
            'total_inflow': 100.25,
            'total_outflow': period == 'day' ? 25.5 : 50.0,
            'change_percent': -50,
          }
      };
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: AnimatedBuilder(
                  animation: state,
                  builder: (_, __) => CashFlowCard(state: state)))));
      await tester.tap(find.text(bengali ? 'দিন' : 'Day'));
      await tester.pump();
      expect(state.timeframe, 0);
      expect(find.text(state.money(25.5)), findsOneWidget);
      expect(find.textContaining(bengali ? 'গতকালের তুলনায়' : 'vs yesterday'),
          findsOneWidget);
      final chart = tester.widget<CustomPaint>(find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is RiverChart));
      expect((chart.painter as RiverChart).inflow[2], 100.25);
      expect((chart.painter as RiverChart).outflow[3], 25.5);
      await tester.tap(find.text(bengali ? 'সপ্তাহ' : 'Week'));
      await tester.pump();
      expect(state.timeframe, 1);
      expect(find.text(state.money(50)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Missing cash flow shows unavailable instead of sample chart',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CashFlowCard(state: ToriState()))));
    expect(find.text('Cash flow data unavailable'), findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is RiverChart),
        findsNothing);
  });
}
