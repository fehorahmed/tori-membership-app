import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tori_mfi_bank/main.dart';
import 'package:tori_mfi_bank/models.dart';
import 'package:tori_mfi_bank/state.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'inter',
      'PlusJakartaSans': 'plus_jakarta_sans',
      'HindSiliguri': 'hind_siliguri',
      'NotoSansBengali': 'noto_sans_bengali'
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load('assets/fonts/' + entry.value + '.ttf'));
      await loader.load();
    }
  });
  test(
      'Original portfolio, transfers, notifications and installments remain linked',
      () {
    final s = ToriState();
    expect(s.balance, 160450);
    expect(s.accounts.length, 4);
    expect(s.profile.fullName, 'Tanvir Ahmed');
    final before = s.balance,
        count = s.transactions.length,
        unread = s.notifications.length;
    s.amount = 15000;
    s.recipient = '01719 283741';
    s.recipientName = 'Tanima H.';
    expect(s.transfer(), isNotNull);
    expect(s.balance, before - 15000);
    expect(s.transactions.length, count + 1);
    expect(s.notifications.length, unread + 1);
    expect(
        s.accounts
            .firstWhere((a) => a.type == AccountType.SAVINGS_CURRENT)
            .balance,
        s.balance);
    s.amount = s.balance + 1;
    expect(s.transfer(), isNull);
    expect(s.balance, before - 15000);
    final loan =
        s.accounts.firstWhere((a) => a.type == AccountType.MFI_LOAN).balance;
    expect(s.payInstallment(), true);
    expect(s.accounts.firstWhere((a) => a.type == AccountType.MFI_LOAN).balance,
        loan - 12500);
  });
  testWidgets('Welcome, OTP and PIN preserve the original sign-in sequence',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = ToriState();
    await tester.pumpWidget(ToriBankApp(state: s, monitorNetwork: false));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to TORI'), findsOneWidget);
    expect(find.text('Verified Gateway'), findsOneWidget);
    await tester.tap(find.text('Continue | এগিয়ে যান'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Verify Mobile OTP'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-input')), '1234');
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SECURITY PIN'), findsOneWidget);
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.loggedIn, true);
    expect(find.text('Tanvir Ahmed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [360.0, 412.0])
    for (final dark in [false, true])
      testWidgets('All tabs fit at $width, dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final s = ToriState()
          ..loggedIn = true
          ..theme = dark ? AppThemeMode.DARK : AppThemeMode.LIGHT;
        await tester.pumpWidget(ToriBankApp(state: s, monitorNetwork: false));
        for (final tab in AppNavTab.values) {
          s.navigate(tab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab.name);
        }
        await tester.pumpWidget(const SizedBox());
      });
  testWidgets('Capture welcome reference', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ToriBankApp(state: ToriState(), monitorNetwork: false)));
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('../tori-reference/flutter').create(recursive: true);
      await File('../tori-reference/flutter/welcome.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
