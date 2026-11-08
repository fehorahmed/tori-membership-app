import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'auth.dart';
import 'dashboard.dart';
import 'accounts.dart';
import 'payments.dart';
import 'profile.dart';
import 'dialogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final state = ToriState();
  await state.loadPreferences();
  runApp(ToriBankApp(state: state));
}

class ToriBankApp extends StatelessWidget {
  final ToriState state;
  final bool monitorNetwork;
  const ToriBankApp(
      {super.key, required this.state, this.monitorNetwork = true});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TORI Bank',
          theme: buildTheme(false),
          darkTheme: buildTheme(true),
          themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => Stack(children: [
                child!,
                if (!state.online)
                  Positioned.fill(
                      child: OfflineScreen(
                          state: state,
                          onRetry: () async {
                            final result =
                                await Connectivity().checkConnectivity();
                            state.online =
                                result.any((r) => r != ConnectivityResult.none);
                            state.changed();
                          })),
              ]),
          home: BankRoot(state: state, monitorNetwork: monitorNetwork)));
}

class BankRoot extends StatefulWidget {
  final ToriState state;
  final bool monitorNetwork;
  const BankRoot({super.key, required this.state, this.monitorNetwork = true});
  @override
  State<BankRoot> createState() => _BankRootState();
}

class _BankRootState extends State<BankRoot> {
  bool online = true;
  StreamSubscription<List<ConnectivityResult>>? connection;
  @override
  void initState() {
    super.initState();
    if (widget.monitorNetwork) {
      check();
      connection = Connectivity().onConnectivityChanged.listen(update);
    }
  }

  void update(List<ConnectivityResult> result) {
    if (mounted) {
      online = result.any((r) => r != ConnectivityResult.none);
      widget.state.online = online;
      widget.state.changed();
    }
  }

  Future<void> check() async {
    try {
      update(await Connectivity().checkConnectivity());
    } catch (_) {}
  }

  @override
  void dispose() {
    connection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state, p = Palette(s.dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: s.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            s.dark ? Brightness.light : Brightness.dark));
    if (!online) return OfflineScreen(state: s, onRetry: check);
    if (!s.loggedIn) return WelcomeScreen(state: s);
    return PopScope(
        canPop: s.tab == AppNavTab.HOME,
        onPopInvokedWithResult: (popped, result) {
          if (!popped) s.navigate(AppNavTab.HOME);
        },
        child: Scaffold(
            body: Ground(
                state: s,
                child: Stack(children: [
                  Positioned.fill(
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: KeyedSubtree(
                              key: ValueKey(s.tab),
                              child: switch (s.tab) {
                                AppNavTab.HOME => HomeScreen(state: s),
                                AppNavTab.ACCOUNTS => AccountsScreen(state: s),
                                AppNavTab.PAYMENTS => PaymentsScreen(state: s),
                                AppNavTab.PROFILE => ProfileScreen(state: s)
                              }))),
                  Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: SafeArea(
                          top: false,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                  child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 448),
                                      child: SizedBox(
                                          height: 88,
                                          child: Stack(
                                              alignment: Alignment.bottomCenter,
                                              children: [
                                                FractionallySizedBox(
                                                    widthFactor: .95,
                                                    child: Container(
                                                        height: 72,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 4),
                                                        decoration: BoxDecoration(
                                                            color: p.surface
                                                                .withValues(
                                                                    alpha: .9),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100),
                                                            border: Border.all(
                                                                color: p.border
                                                                    .withValues(
                                                                        alpha: .6)),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                  color: Color(
                                                                      0x28000000),
                                                                  blurRadius:
                                                                      24,
                                                                  offset:
                                                                      Offset(0,
                                                                          12))
                                                            ]),
                                                        child: Row(children: [
                                                          nav(0),
                                                          nav(1),
                                                          const SizedBox(
                                                              width: 64),
                                                          nav(2),
                                                          nav(3)
                                                        ]))),
                                                Positioned(
                                                    bottom: 28,
                                                    child: Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: p.primary,
                                                            border: Border.all(
                                                                color: Colors.white,
                                                                width: 4),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                  color: Color(
                                                                      0x33000000),
                                                                  blurRadius:
                                                                      12,
                                                                  offset:
                                                                      Offset(
                                                                          0, 6))
                                                            ]),
                                                        child: IconButton(
                                                            tooltip:
                                                                'Scan QR Code',
                                                            onPressed: () => showQrScanner(
                                                                context, s),
                                                            icon: Icon(Icons.qr_code_scanner,
                                                                size: 28,
                                                                color: s.dark
                                                                    ? const Color(0xFF0F172A)
                                                                    : Colors.white))))
                                              ])))))))
                ]))));
  }

  Widget nav(int i) {
    final s = widget.state, p = Palette(s.dark), selected = s.tab.index == i;
    final label = [
      s.tr('Home', 'হোম'),
      s.tr('Accounts', 'হিসাব'),
      s.tr('Payments', 'পেমেন্ট'),
      s.tr('Profile', 'প্রোফাইল')
    ][i];
    return Expanded(
        child: InkWell(
            onTap: () => s.navigate(AppNavTab.values[i]),
            borderRadius: BorderRadius.circular(40),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                  const [
                    Icons.home,
                    Icons.account_balance_wallet,
                    Icons.swap_horiz,
                    Icons.person
                  ][i],
                  size: 20,
                  color: selected ? p.primary : p.muted),
              gap(2),
              text(label,
                  size: 10, color: selected ? p.primary : p.muted, lines: 1)
            ])));
  }
}

class OfflineScreen extends StatelessWidget {
  final ToriState state;
  final VoidCallback onRetry;
  const OfflineScreen({super.key, required this.state, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final s = state, p = Palette(s.dark);
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: stack([
                  Row(children: [
                    const Emblem(size: 44),
                    hgap(12),
                    Expanded(
                        child: stack([
                      text('TORI BANK', size: 18, color: p.ink),
                      text(
                          s.tr('MFI & Digital Banking',
                              'এমএফআই ও ডিজিটাল ব্যাংকিং'),
                          size: 11,
                          color: p.muted)
                    ], spacing: 4)),
                    link(s.bengali ? 'English' : 'বাংলা',
                        () => s.setLanguage(!s.bengali))
                  ]),
                  gap(32),
                  Center(
                      child: Icon(Icons.wifi_off_rounded,
                          size: 96, color: p.muted)),
                  Center(
                      child: pill(
                          s.tr('DISCONNECTED • STRICT ONLINE ONLY',
                              'সংযোগ বিচ্ছিন্ন • অফলাইন মোড সক্রিয়'),
                          p.error)),
                  Center(
                      child: text(
                          s.tr('Internet Connection Required',
                              'ইন্টারনেট সংযোগ প্রয়োজন'),
                          size: 26,
                          color: p.ink,
                          align: TextAlign.center)),
                  panel(
                      p,
                      stack([
                        infoRow(s.tr('Network Status', 'নেটওয়ার্ক স্থিতি'),
                            s.tr('No Connection', 'সংযোগহীন'), p),
                        infoRow(s.tr('Banking Gateway', 'সিকিউরিটি গেটওয়ে'),
                            s.tr('Access Blocked', 'অফলাইন ব্লক সক্রিয়'), p),
                        infoRow(
                            s.tr('Offline Data', 'অফলাইন ক্যাশ ডেটা'),
                            s.tr('Disabled (Secure)', 'নিষ্ক্রিয় (সুরক্ষিত)'),
                            p)
                      ])),
                  primary(
                      s.tr('Retry Connection', 'পুনরায় চেষ্টা করুন'), onRetry,
                      icon: Icons.refresh),
                  secondary(
                      s.tr('Open Network Settings', 'নেটওয়ার্ক সেটিংস খুলুন'),
                      () async {
                    try {
                      await AppSettings.openAppSettings(
                          type: AppSettingsType.wifi);
                    } catch (_) {
                      if (context.mounted)
                        toast(
                            context,
                            s.tr('Could not open settings',
                                'সেটিংস খোলা সম্ভব হয়নি'));
                    }
                  }, p, icon: Icons.settings)
                ]))));
  }
}
