import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/main.dart';
import 'package:tori_mfi_bank/models.dart';
import 'package:tori_mfi_bank/state.dart';
import 'package:tori_mfi_bank/dialogs.dart';
import 'package:tori_mfi_bank/profile.dart';
import 'package:tori_mfi_bank/payment_security.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Authorization preserves the unconfigured backend and balance',
      (t) async {
    final s = ToriState();
    await t.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: SingleChildScrollView(
                      child: PaymentSecurityPanel(
                          state: s,
                          onAuthorized: () =>
                              showBackendUnavailable(context, s))),
                ))));
    await t.enterText(find.byType(TextField), '1234');
    await t.pump(const Duration(milliseconds: 1300));
    await t.tap(find.byIcon(Icons.fingerprint));
    await t.pump();
    await t.ensureVisible(find.text('Confirm & Authorize Transfer'));
    await t.tap(find.text('Confirm & Authorize Transfer'));
    await t.pumpAndSettle();
    expect(find.text(s.transferUnavailable), findsOneWidget);
    expect(s.balance, 160450);
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(s.balance, 160450);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Profile dialogs fit narrow screens and close cleanly',
      (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final s = ToriState()..loggedIn = true;
    late BuildContext host;
    await t.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      host = context;
      return const Scaffold(body: SizedBox());
    })));
    for (final show in [showKyc, showNominee, showLanguage, showSupport]) {
      show(host, s);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      Navigator.of(host).pop();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('Bengali tabs and offline overlay fit a narrow screen',
      (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final s = ToriState()
      ..loggedIn = true
      ..bengali = true;
    await t.pumpWidget(ToriBankApp(state: s, monitorNetwork: false));
    for (final tab in AppNavTab.values) {
      s.navigate(tab);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: tab.name);
    }
    s.online = false;
    s.changed();
    await t.pumpAndSettle();
    expect(find.byType(OfflineScreen), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
