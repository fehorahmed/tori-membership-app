import 'send_money.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dialogs.dart';

class HomeScreen extends StatefulWidget {
  final ToriState state;
  const HomeScreen({super.key, required this.state});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool expanded = false, revealed = false;
  Timer? timer;
  ToriState get s => widget.state;
  Palette get p => Palette(s.dark);
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void accounts(AccountCategory filter) {
    s.accountFilter = filter;
    s.navigate(AppNavTab.ACCOUNTS);
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 230,
            child: CustomPaint(painter: HomeWash(s.dark))),
        SafeArea(
            bottom: false,
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                    child: Column(children: [
                      SizedBox(
                          height: 56,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(children: [
                                Container(
                                    width: 54,
                                    height: 54,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFE11D48),
                                            width: 2)),
                                    child: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFE11D48),
                                        child: text(
                                            s.profile.fullName.isEmpty
                                                ? 'T'
                                                : s.profile.fullName[0],
                                            size: 20,
                                            color: Colors.white))),
                                hgap(12),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        text(s.profile.fullName,
                                            size: 16,
                                            color: p.ink,
                                            family: 'PlusJakartaSans'),
                                        hgap(4),
                                        if (s.profile.isVerified)
                                          const Icon(Icons.verified,
                                              size: 16,
                                              color: Color(0xFF3B82F6))
                                      ]),
                                      gap(2),
                                      InkWell(
                                          onTap: () {
                                            timer?.cancel();
                                            setState(
                                                () => revealed = !revealed);
                                            if (revealed)
                                              timer = Timer(
                                                  const Duration(
                                                      milliseconds: 3500), () {
                                                if (mounted)
                                                  setState(
                                                      () => revealed = false);
                                              });
                                          },
                                          child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              height: 28,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              decoration: BoxDecoration(
                                                  color: p.surface,
                                                  border: Border.all(
                                                      color: p.border),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100)),
                                              child: Row(children: [
                                                CircleAvatar(
                                                    radius: 9,
                                                    backgroundColor:
                                                        const Color(0xFFE11D48),
                                                    child: text('৳',
                                                        size: 11,
                                                        color: Colors.white)),
                                                hgap(6),
                                                AnimatedSwitcher(
                                                    duration: const Duration(milliseconds: 300),
                                                    transitionBuilder: (child, animation) {
                                                      return SlideTransition(
                                                        position: Tween<Offset>(
                                                          begin: const Offset(0.3, 0),
                                                          end: Offset.zero,
                                                        ).animate(animation),
                                                        child: FadeTransition(opacity: animation, child: child),
                                                      );
                                                    },
                                                    child: KeyedSubtree(
                                                        key: ValueKey<bool>(revealed),
                                                        child: text(
                                                            revealed
                                                                ? s.money(s.balance)
                                                                : s.tr(
                                                                    'Tap for Balance',
                                                                    'ব্যালেন্স দেখুন'),
                                                            size: 12,
                                                            color: p.ink,
                                                            weight: FontWeight.w600)))
                                              ])))
                                    ]),
                                hgap(14),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: p.surface,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Row(children: [
                                      const Icon(Icons.stars,
                                          color: Color(0xFFF59E0B), size: 16),
                                      hgap(4),
                                      text(
                                          NumberFormat('#,##0')
                                              .format(s.profile.rewardPoints),
                                          size: 12,
                                          color: p.ink)
                                    ])),
                                hgap(),
                                roundIcon(Icons.search, p, onTap: () {}),
                                hgap(),
                                roundIcon(
                                    s.dark ? Icons.light_mode : Icons.dark_mode,
                                    p,
                                    onTap: s.toggleTheme)
                              ]))),
                      gap(20),
                      panel(
                          p,
                          Column(children: [
                            for (int row = 0;
                                row < (expanded ? 2 : 1);
                                row++) ...[
                              if (row > 0) gap(16),
                              Row(children: [
                                for (int i = row * 4; i < row * 4 + 4; i++)
                                  Expanded(
                                      child: ServiceTile(
                                          label: [
                                            s.tr('Send Money', 'সেন্ড মানি'),
                                            s.tr('Passbook', 'পাসবুক'),
                                            'DPS',
                                            'FDR',
                                            s.tr('Loan', 'লোন'),
                                            s.tr('Add Money', 'অ্যাড মানি'),
                                            s.tr('Savings', 'সঞ্চয়'),
                                            s.tr('Statement', 'স্টেটমেন্ট')
                                          ][i],
                                          icon: const [
                                            Icons.send,
                                            Icons.description,
                                            Icons.savings,
                                            Icons.account_balance,
                                            Icons.request_quote,
                                            Icons.add_card,
                                            Icons.account_balance_wallet,
                                            Icons.list_alt
                                          ][i],
                                          color: const [
                                            Color(0xFFE11D48),
                                            Color(0xFF0D9488),
                                            Color(0xFF7C3AED),
                                            Color(0xFFD97706),
                                            Color(0xFF2563EB),
                                            Color(0xFF0891B2),
                                            Color(0xFF4F46E5),
                                            Color(0xFF64748B)
                                          ][i],
                                          p: p,
                                          onTap: () {
                                            switch (i) {
                                              case 0:
                                                showSendMoney(context, s);
                                              case 1:
                                              case 7:
                                                showStatement(context, s);
                                              case 2:
                                              case 3:
                                              case 6:
                                                accounts(
                                                    AccountCategory.DEPOSIT);
                                              case 4:
                                                accounts(AccountCategory.LOANS);
                                              case 5:
                                                break;
                                            }
                                          }))
                              ])
                            ],
                            gap(12),
                            link(
                                expanded
                                    ? s.tr('See Less ⌃', 'সংক্ষিপ্ত করুন ⌃')
                                    : s.tr('See More ⌄', 'আরও দেখুন ⌄'),
                                () => setState(() => expanded = !expanded),
                                color: const Color(0xFFE11D48),
                                size: 11)
                          ]),
                          padding: 16,
                          radius: 22),
                      gap(20),
                      sectionTitle(s.tr('Quick Send', 'দ্রুত পাঠান'), p),
                      gap(12),
                      SizedBox(
                          height: 90,
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                SizedBox(
                                    width: 66,
                                    child: Column(children: [
                                      roundIcon(Icons.add, p,
                                          size: 48, onTap: () {}),
                                      gap(6),
                                      text(s.tr('Add New', 'নতুন'),
                                          size: 11, color: p.muted)
                                    ])),
                                for (final f in s.favorites)
                                  SizedBox(
                                      width: 72,
                                      child: InkWell(
                                          onTap: () {
                                            s.selectFavorite(f);
                                            s.navigate(AppNavTab.PAYMENTS);
                                          },
                                          child: Column(children: [
                                            CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    Color(f.badgeColorHex)
                                                        .withValues(alpha: .12),
                                                child: text(
                                                    f.initials ??
                                                        f.shortName
                                                            .substring(0, 1),
                                                    size: 17,
                                                    color: Color(
                                                        f.badgeColorHex))),
                                            gap(6),
                                            text(f.shortName,
                                                size: 11,
                                                color: p.ink,
                                                lines: 1)
                                          ])))
                              ])),
                      for (final a in s.accounts
                          .where((a) => a.type == AccountType.MFI_LOAN)
                          .take(1))
                        panel(
                            p,
                            Row(children: [
                              const Icon(Icons.calendar_month,
                                  color: Color(0xFFD97706), size: 28),
                              hgap(12),
                              Expanded(
                                  child: stack([
                                text(
                                    s.tr('Upcoming Loan EMI',
                                        'আসন্ন ঋণের কিস্তি'),
                                    size: 12,
                                    color: p.ink),
                                text(
                                    '${s.money(a.nextInstallmentAmount ?? 0)} • ${s.bengali ? a.nextDueDateBn : a.nextDueDateEn}',
                                    size: 11,
                                    color: p.muted)
                              ], spacing: 4)),
                              link(s.tr('Pay Now', 'পরিশোধ করুন'), () {
                                showBackendUnavailable(context, s, loan: true);
                              }, color: const Color(0xFFD97706))
                            ]),
                            color: s.dark ? p.surface : const Color(0xFFFFFBEB),
                            padding: 14,
                            radius: 16),
                      gap(14),
                      CashFlowCard(
                          state: s,
                          onSeeAll: () => s.navigate(AppNavTab.PAYMENTS)),
                      gap(14),
                      PromoCarousel(state: s),
                      gap(18),
                      Row(children: [
                        for (final label in [
                          s.tr('My Offer', 'মাই অফার'),
                          s.tr('Coupon', 'কুপন'),
                          s.tr('Reward', 'রিওয়ার্ড')
                        ])
                          Expanded(
                              child: Container(
                                  height: 38,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: p.raised,
                                      border: Border.all(color: p.border),
                                      borderRadius: BorderRadius.circular(19)),
                                  child: Center(
                                      child: text(label,
                                          size: 10, color: p.muted))))
                      ]),
                      gap(14),
                      sectionTitle(
                          s.tr('Recent Transactions', 'সাম্প্রতিক লেনদেন'), p,
                          action: s.tr('View All', 'সব দেখুন'),
                          onAction: () => s.navigate(AppNavTab.PAYMENTS)),
                      gap(10),
                      for (final t in s.transactions.take(3))
                        TransactionRow(
                            transaction: t,
                            state: s,
                            onTap: () => showStatement(context, s)),
                      gap(20)
                    ]))))
      ]);
  Widget story(String tag, String title, String subtitle, String cta,
          Color color, VoidCallback onTap) =>
      Container(
          width: 210,
          margin: const EdgeInsets.only(right: 12),
          child: panel(
              p,
              stack([
                pill(tag, color),
                text(title, size: 14, color: p.ink),
                text(subtitle, size: 11, color: p.muted),
                link(cta, onTap, color: color)
              ], spacing: 10),
              radius: 18));
}

class ServiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Palette p;
  final VoidCallback onTap;
  const ServiceTile(
      {super.key,
      required this.label,
      required this.icon,
      required this.color,
      required this.p,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Column(children: [
        Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: .2))),
            child: Icon(icon, color: color, size: 26)),
        gap(6),
        SizedBox(
            height: 28,
            child: text(label,
                size: 10.5,
                color: p.ink,
                align: TextAlign.center,
                lines: 2,
                weight: FontWeight.w500))
      ]));
}

class CashFlowCard extends StatelessWidget {
  final ToriState state;
  final VoidCallback? onSeeAll;
  const CashFlowCard({super.key, required this.state, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    final s = state, p = Palette(s.dark), idx = s.timeframe;
    final data = <List<double>>[
      [15, 30, 25, 40, 35, 20, 15],
      [20, 45, 35, 60, 48, 75, 55],
      [40, 55, 65, 85]
    ][idx];
    final labels = [
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
      ['2021', '2022', '2023', '2024']
    ][idx];
    return panel(
        p,
        stack([
          sectionTitle(s.tr('Cash Flow Summary', 'ক্যাশ ফ্লো সামারি'), p,
              action: s.tr('See All >', 'সব দেখুন >'), onAction: onSeeAll),
          text(s.tr('Inflow vs Outflow River Chart', 'আয় ও ব্যয়ের প্রবাহ'),
              size: 11, color: p.muted),
          tabs([
            s.tr('Week', 'সপ্তাহ'),
            s.tr('Month', 'মাস'),
            s.tr('Year', 'বছর')
          ], idx, (v) {
            s.timeframe = v;
            s.changed();
          }, p),
          Row(children: [
            Expanded(
                child: stack([
              text(s.tr('Net Spending', 'মোট ব্যয়'), size: 11, color: p.muted),
              text(s.money(s.spending * [.18, 1, 12][idx]),
                  size: 20, color: p.ink)
            ], spacing: 4)),
            pill(
                [
                  '▼ 12.4% vs last week',
                  '▲ 8.2% vs last month',
                  '▲ 4.8% vs last year'
                ][idx],
                idx == 0 ? p.primary : p.error,
                size: 10)
          ]),
          SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(painter: RiverChart(data, p))),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  labels.map((v) => text(v, size: 10, color: p.muted)).toList())
        ], spacing: 12),
        radius: 22,
        padding: 18);
  }
}

class RiverChart extends CustomPainter {
  final List<double> values;
  final Palette p;
  RiverChart(this.values, this.p);
  @override
  void paint(Canvas c, Size s) {
    for (int i = 0; i < 4; i++)
      c.drawLine(
          Offset(0, s.height * i / 3),
          Offset(s.width, s.height * i / 3),
          Paint()
            ..color = p.border
            ..strokeWidth = .5);
    for (int series = 1; series >= 0; series--) {
      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final x = s.width * i / (values.length - 1),
            y = s.height -
                (values[i] * (series == 0 ? 1 : .65) + series * 12) /
                    100 *
                    s.height;
        if (i == 0)
          path.moveTo(x, y);
        else {
          final px = s.width * (i - 1) / (values.length - 1),
              py = s.height -
                  (values[i - 1] * (series == 0 ? 1 : .65) + series * 12) /
                      100 *
                      s.height;
          path.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
        }
      }
      final color =
          series == 0 ? const Color(0xFF0D9488) : const Color(0xFFFB7185);
      c.drawPath(
          Path.from(path)
            ..lineTo(s.width, s.height)
            ..lineTo(0, s.height)
            ..close(),
          Paint()
            ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: .3), color.withValues(alpha: .02)])
                .createShader(Offset.zero & s));
      c.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant RiverChart old) => true;
}

class TransactionRow extends StatelessWidget {
  final TransactionItem transaction;
  final ToriState state;
  final VoidCallback? onTap;
  const TransactionRow(
      {super.key, required this.transaction, required this.state, this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = transaction, s = state, p = Palette(s.dark);
    final color = t.isCredit ? p.primary : p.error;
    return InkWell(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      switch (t.iconType) {
                        'agro' => Icons.agriculture,
                        'cart' => Icons.shopping_cart_outlined,
                        'installment' => Icons.receipt_long,
                        'profit' => Icons.savings_outlined,
                        _ => Icons.swap_horiz
                      },
                      color: color,
                      size: 20)),
              hgap(12),
              Expanded(
                  child: stack([
                text(s.bengali ? t.titleBn : t.titleEn,
                    size: 12, color: p.ink, lines: 1),
                text(s.bengali ? t.timeBn : t.timeEn,
                    size: 10, color: p.muted, lines: 1)
              ], spacing: 4)),
              hgap(6),
              stack([
                text(
                    s.hidden
                        ? '••••••'
                        : '${t.isCredit ? '+' : '−'} ${s.money(t.amount)}',
                    size: 12,
                    color: color),
                text(s.bengali ? t.statusBn : t.statusEn,
                    size: 9, color: p.muted)
              ], spacing: 4, align: CrossAxisAlignment.end)
            ])));
  }
}

class PromoCarousel extends StatefulWidget {
  final ToriState state;
  const PromoCarousel({super.key, required this.state});
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int index = 0;
  final controller = PageController();
  Timer? timer;
  bool paused = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!paused && controller.hasClients)
        controller.animateToPage((index + 1) % 3,
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final items = [
      [
        s.tr('DPS SAVINGS', 'ডিপিএস সঞ্চয়'),
        s.tr('Enjoy up to 9.5% Profit on TORI DPS!',
            'TORI ডিপিএস-এ পাচ্ছেন ৯.৫% পর্যন্ত মুনাফা!'),
        s.tr('Open DPS', 'ডিপিএস খুলুন')
      ],
      [
        s.tr('CASHBACK OFFER', 'ক্যাশব্যাক অফার'),
        s.tr('Get ৳ 50 Cashback on first Bill Pay!',
            'প্রথম বিল পে-তে ৫০ টাকা নিশ্চিত ক্যাশব্যাক!'),
        s.tr('Pay Bill', 'বিল পে করুন')
      ],
      [
        s.tr('MICRO LOAN', 'ক্ষুদ্র ঋণ'),
        s.tr('Instant Loan up to ৳ 20,000 with low interest',
            'সহজ শর্তে ২০,০০০ টাকা পর্যন্ত ইনস্ট্যান্ট লোন!'),
        s.tr('Apply Now', 'আবেদন করুন')
      ]
    ];
    final colors = const [
      [Color(0xFF0F172A), Color(0xFF1E293B)],
      [Color(0xFF064E3B), Color(0xFF065F46)],
      [Color(0xFF4C0519), Color(0xFF881337)]
    ];
    return Column(children: [
      Listener(
          onPointerDown: (_) => paused = true,
          onPointerUp: (_) => paused = false,
          onPointerCancel: (_) => paused = false,
          child: SizedBox(
              height: 140,
              child: PageView(
                  controller: controller,
                  onPageChanged: (v) => setState(() => index = v),
                  children: [
                    for (int i = 0; i < 3; i++)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors[i])),
                              child: Stack(children: [
                                Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                        [
                                          Icons.savings,
                                          Icons.trending_up,
                                          Icons.account_balance
                                        ][i],
                                        size: 160,
                                        color: Colors.white.withValues(alpha: .15))),
                                Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          pill(items[i][0], Colors.white,
                                              background:
                                                  Colors.white.withValues(alpha: .2)),
                                          FractionallySizedBox(
                                              widthFactor: .75,
                                              child: text(items[i][1],
                                                  size: 14,
                                                  color: Colors.white,
                                                  lines: 2)),
                                          Row(children: [
                                            text(items[i][2],
                                                size: 12, color: Colors.white),
                                            hgap(4),
                                            const Icon(Icons.arrow_forward,
                                                size: 16, color: Colors.white)
                                          ])
                                        ]))
                              ])))
                  ]))),
      gap(12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < 3; i++)
          Container(
              width: i == index ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                  color:
                      Palette(s.dark).primary.withValues(alpha: i == index ? 1 : .2),
                  borderRadius: BorderRadius.circular(4)))
      ])
    ]);
  }
}

class HomeWash extends CustomPainter {
  final bool dark;
  HomeWash(this.dark);
  @override
  void paint(Canvas c, Size s) {
    final h = DateTime.now().hour;
    final colors = dark
        ? const [Color(0xFF0C1E3A), Color(0xFF071224), Color(0x0005070D)]
        : h >= 4 && h <= 6
            ? const [Color(0xFFFFEDD5), Color(0xFFFEF3C7), Color(0x00F5F7FB)]
            : h >= 7 && h <= 15
                ? const [
                    Color(0xFFE0F2FE),
                    Color(0xFFBAE6FD),
                    Color(0x00F5F7FB)
                  ]
                : h >= 16 && h <= 18
                    ? const [
                        Color(0xFFFEF3C7),
                        Color(0xFFFDE68A),
                        Color(0x00F5F7FB)
                      ]
                    : const [
                        Color(0xFFDBEAFE),
                        Color(0xFFBFDBFE),
                        Color(0x00F5F7FB)
                      ];
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors)
              .createShader(Offset.zero & s));
    c.save();
    c.translate(s.width - 76, 48);
    final hull = Path()
      ..moveTo(6, 39)
      ..cubicTo(18, 51, 42, 51, 54, 39)
      ..cubicTo(42, 43.2, 18, 43.2, 6, 39)
      ..close();
    c.drawPath(hull, Paint()..color = const Color(0x40F59E0B));
    c.drawPath(
        Path()
          ..moveTo(30, 15)
          ..cubicTo(40.8, 25.2, 39, 36, 30, 37.2)
          ..close(),
        Paint()..color = const Color(0x4DD97706));
    c.drawLine(
        const Offset(30, 13.2),
        const Offset(30, 39.6),
        Paint()
          ..color = const Color(0x40F59E0B)
          ..strokeWidth = 1.5);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant HomeWash old) => dark != old.dark;
}
