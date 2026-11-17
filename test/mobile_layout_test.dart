import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tori_mfi_bank/auth.dart';
import 'package:tori_mfi_bank/dashboard.dart';
import 'package:tori_mfi_bank/payments.dart';
import 'package:tori_mfi_bank/profile.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final bengali in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('Mobile layout $width bn=$bengali scale=$scale', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final state = ToriState()..bengali = bengali;
          for (final screen in <Widget>[
            HomeScreen(state: state), ProfileScreen(state: state),
            PaymentsScreen(state: state), WelcomeScreen(state: state),
          ]) {
            await tester.pumpWidget(MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
              home: Scaffold(body: screen),
            ));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: '${screen.runtimeType} at $width, scale=$scale, bn=$bengali');
            if (screen is HomeScreen) {
              await tester.tap(find.text(state.tr('See More ⌄', 'আরও দেখুন ⌄')));
              await tester.pump();
              expect(tester.takeException(), isNull, reason: 'Expanded Home at $width');
            }
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      }
    }
  }
}
