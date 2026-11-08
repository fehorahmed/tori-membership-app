import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dashboard.dart';

Future<T?> openPage<T>(BuildContext context, ToriState state, String title,
        Widget Function(BuildContext) content) =>
    Navigator.of(context).push<T>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              final p = Palette(state.dark);
              return Scaffold(
                  backgroundColor: p.ground,
                  appBar: AppBar(
                      backgroundColor: p.surface,
                      surfaceTintColor: Colors.transparent,
                      title: text(title, size: 18, color: p.ink),
                      leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(pageContext))),
                  body: SafeArea(top: false, child: content(pageContext)));
            })));
Widget pageBody(List<Widget> children) => SingleChildScrollView(
    padding: const EdgeInsets.all(20), child: stack(children, spacing: 18));

Future<void> showBackendUnavailable(BuildContext context, ToriState s,
        {bool loan = false}) =>
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(s.tr(
                  'Server or Network Error', 'সার্ভার বা নেটওয়ার্ক ত্রুটি')),
              content: Text(loan ? s.loanUnavailable : s.transferUnavailable),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(s.tr('Dismiss', 'বাদ দিন'))),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showBackendUnavailable(context, s, loan: loan);
                    },
                    child: Text(s.tr('Retry', 'পুনরায় চেষ্টা করুন')))
              ],
            ));
Future<void> showSuccess(BuildContext context, ToriState s,
        {String? message}) =>
    showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: stack([
                  const Center(
                      child: Icon(Icons.check_circle,
                          color: Color(0xFF10B981), size: 72)),
                  Center(
                      child: text(
                          s.tr('Transaction Successful!',
                              'লেনদেন সম্পন্ন হয়েছে!'),
                          size: 21,
                          align: TextAlign.center)),
                  Center(
                      child: text(
                          message ??
                              s.tr(
                                  'Your transaction has been processed instantly',
                                  'আপনার লেনদেন সফলভাবে সম্পন্ন হয়েছে'),
                          size: 13,
                          align: TextAlign.center)),
                  secondary(s.tr('Share Receipt', 'শেয়ার করুন'), () {
                    Clipboard.setData(ClipboardData(
                        text: message ?? 'TORI Transaction Successful'));
                    toast(
                        context, s.tr('Receipt copied', 'রশিদ কপি করা হয়েছে'));
                  }, Palette(s.dark)),
                  primary(s.tr('Done', 'সম্পন্ন'), () => Navigator.pop(ctx))
                ]))));
Future<void> showAddMoney(BuildContext context, ToriState s) async {
  final amount = TextEditingController();
  String method = 'Bank Transfer';
  int step = 1;
  await openPage<void>(
      context,
      s,
      s.tr('Add Money', 'টাকা যোগ করুন'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark);
            return pageBody([
              text(
                  step == 1
                      ? s.tr('Select Method', 'পদ্ধতি নির্বাচন করুন')
                      : s.tr('Summary', 'সারসংক্ষেপ'),
                  size: 20,
                  color: p.ink),
              if (step == 1) ...[
                for (final value in [
                  'Bank Transfer',
                  'Visa / MasterCard',
                  'bKash / Nagad'
                ])
                  panel(
                      p,
                      RadioListTile<String>(
                          value: value,
                          groupValue: method,
                          onChanged: (v) => set(() => method = v!),
                          title: text(value, color: p.ink),
                          secondary: Icon(
                              value.startsWith('Bank')
                                  ? Icons.account_balance
                                  : value.startsWith('Visa')
                                      ? Icons.credit_card
                                      : Icons.phone_android,
                              color: p.primary)),
                      padding: 0),
                field(s.tr('Amount', 'পরিমাণ'), amount, p,
                    hint: '0.00',
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true))
              ] else
                panel(
                    p,
                    stack([
                      infoRow(s.tr('Source', 'উৎস'), method, p),
                      infoRow(s.tr('Amount', 'পরিমাণ'), '৳ ${amount.text}', p),
                      Divider(color: p.border),
                      infoRow(s.tr('Total', 'মোট'), '৳ ${amount.text}', p)
                    ])),
              primary(
                  step == 1
                      ? s.tr('Continue', 'পরবর্তী')
                      : s.tr('Confirm', 'নিশ্চিত করুন'), () {
                if (step == 1)
                  set(() => step = 2);
                else {
                  s.addMoney(double.tryParse(amount.text) ?? 0, method);
                  Navigator.pop(ctx);
                }
              })
            ]);
          }));
  amount.dispose();
}

Future<void> showOpenDeposit(BuildContext context, ToriState s) async {
  final amount = TextEditingController(text: '5000');
  int selected = 0;
  await openPage<void>(
      context,
      s,
      s.tr('Open Account', 'হিসাব খুলুন'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark);
            return pageBody([
              text(s.tr('Select Plan', 'প্ল্যান নির্বাচন করুন'),
                  size: 20, color: p.ink),
              tabs(['Monthly DPS', 'Fixed FDR'], selected,
                  (v) => set(() => selected = v), p),
              field(s.tr('Amount', 'পরিমাণ'), amount, p,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true)),
              primary(s.tr('Activate Now', 'চালু করুন'), () {
                final ok = s.openDeposit(
                    selected == 0
                        ? AccountType.SHARIAH_DPS
                        : AccountType.FIXED_DEPOSIT_FDR,
                    'New Account',
                    double.tryParse(amount.text) ?? 0,
                    '3 Years');
                if (ok) {
                  Navigator.pop(ctx);
                } else
                  toast(
                      ctx, s.tr('Insufficient balance', 'অপর্যাপ্ত ব্যালেন্স'));
              })
            ]);
          }));
  amount.dispose();
}

Future<void> showQrScanner(BuildContext context, ToriState s) async {
  await openPage<void>(
      context,
      s,
      s.tr('Scan QR', 'কিউআর স্ক্যান'),
      (ctx) => pageBody([
            Container(
                height: 360,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(24)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF10B981), width: 3),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Center(
                              child: Icon(Icons.qr_code_scanner,
                                  color: Colors.white24, size: 120))),
                      gap(24),
                      text(
                          s.tr('Align QR code inside the frame',
                              'ফ্রেমের মধ্যে কোডটি রাখুন'),
                          size: 12,
                          color: Colors.white)
                    ])),
            primary('Mock Scan', () {
              s.updateRecipient('01700000000');
              s.navigate(AppNavTab.PAYMENTS);
              Navigator.pop(ctx);
            })
          ]));
}

Future<void> showMfiPayment(BuildContext context, ToriState s) async {
  await openPage<void>(context, s, s.tr('MFI Installments', 'এমএফআই কিস্তি'),
      (ctx) {
    final p = Palette(s.dark);
    return pageBody([
      text(s.tr('Installment List', 'কিস্তির তালিকা'), size: 20, color: p.ink),
      for (int i = 0; i < 3; i++)
        panel(
            p,
            Row(children: [
              Expanded(
                  child: stack([
                text(['15 Oct 2024', '15 Sep 2024', '15 Aug 2024'][i],
                    color: p.ink),
                text('৳ 12,500.00', size: 16, color: p.ink)
              ])),
              pill(i == 0 ? 'Due Soon' : 'Paid',
                  i == 0 ? const Color(0xFFD97706) : p.primary)
            ])),
      text(s.tr('Payment Summary', 'পেমেন্ট সারসংক্ষেপ'),
          size: 20, color: p.ink),
      panel(
          p,
          stack([
            infoRow(s.tr('Total Payable', 'মোট প্রদেয়'), '৳ 12,500.00', p),
            infoRow(s.tr('Source Account', 'উৎস হিসাব'), 'A/C •••• 9204', p)
          ])),
      primary(s.tr('Pay Now', 'পরিশোধ করুন'), () {
        Navigator.pop(ctx);
        showBackendUnavailable(context, s, loan: true);
      })
    ]);
  });
}

Future<void> showAnalytics(BuildContext context, ToriState s) async =>
    openPage<void>(context, s, s.tr('Financial Analytics', 'আর্থিক বিশ্লেষণ'),
        (ctx) {
      final p = Palette(s.dark);
      return pageBody([
        CashFlowCard(state: s),
        Row(children: [
          Expanded(
              child: panel(
                  p,
                  stack([
                    text(s.tr('Total Income', 'মোট আয়'),
                        size: 11, color: p.muted),
                    text(s.money(s.income), size: 18, color: p.primary)
                  ]))),
          hgap(12),
          Expanded(
              child: panel(
                  p,
                  stack([
                    text(s.tr('Total Spending', 'মোট ব্যয়'),
                        size: 11, color: p.muted),
                    text(s.money(s.spending), size: 18, color: p.error)
                  ])))
        ]),
        text(s.tr('Category Breakdown', 'বিভাগভিত্তিক বিশ্লেষণ'),
            size: 20, color: p.ink),
        for (final category in s.transactions.map((t) => t.categoryEn).toSet())
          infoRow(
              category,
              s.money(s.transactions
                  .where((t) => t.categoryEn == category)
                  .fold<double>(0, (v, t) => v + t.amount)),
              p),
        text(s.tr('Related Transactions', 'সম্পর্কিত লেনদেন সমূহ'),
            size: 20, color: p.ink),
        for (final t in s.transactions)
          TransactionRow(
              transaction: t, state: s, onTap: () => showReceipt(ctx, s, t)),
        primary(s.tr('Close', 'বন্ধ করুন'), () => Navigator.pop(ctx))
      ]);
    });

Future<void> showStatement(BuildContext context, ToriState s) async =>
    openPage<void>(
        context,
        s,
        s.tr('Account Statement', 'অ্যাকাউন্ট স্টেটমেন্ট'),
        (ctx) => StatementView(state: s));

class StatementView extends StatefulWidget {
  final ToriState state;
  const StatementView({super.key, required this.state});
  @override
  State<StatementView> createState() => _StatementViewState();
}

class _StatementViewState extends State<StatementView> {
  final search = TextEditingController();
  int date = 0, type = 0;
  String category = 'ALL';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state, p = Palette(s.dark);
    final query = search.text.trim().toLowerCase();
    final filtered = s.transactions.where((t) {
      final hay =
          '${t.titleEn} ${t.titleBn} ${t.txnId} ${t.categoryEn} ${t.categoryBn} ${t.note ?? ''} ${t.amount} ${s.money(t.amount)}'
              .toLowerCase();
      final time = '${t.timeEn} ${t.timeBn}'.toLowerCase();
      return hay.contains(query) &&
          (category == 'ALL' || t.categoryEn == category) &&
          (type == 0 || (type == 1 ? t.isCredit : !t.isCredit)) &&
          switch (date) {
            0 => true,
            1 => time.contains('today') || time.contains('আজ'),
            2 || 3 => ['today', 'yesterday', 'oct', 'আজ', 'গতকাল', 'অক্টোবর']
                .any(time.contains),
            _ => ['sep', 'aug', 'সেপ্টেম্বর', 'আগস্ট'].any(time.contains)
          };
    }).toList();
    return pageBody([
      panel(
          p,
          stack([
            text(s.tr('Transaction History', 'লেনদেন ইতিহাস'),
                size: 21, color: p.ink),
            text(
                s.tr('Search, filter and review your account activity',
                    'আপনার হিসাবের লেনদেন অনুসন্ধান ও পর্যালোচনা করুন'),
                size: 12,
                color: p.muted),
            Row(children: [
              Expanded(
                  child: stack([
                text(s.tr('Money In', 'মোট জমা'), size: 11, color: p.muted),
                text(
                    s.money(
                        filtered
                            .where((t) => t.isCredit)
                            .fold<double>(0, (v, t) => v + t.amount),
                        mask: true),
                    size: 18,
                    color: p.primary)
              ])),
              Expanded(
                  child: stack([
                text(s.tr('Money Out', 'মোট খরচ'), size: 11, color: p.muted),
                text(
                    s.money(
                        filtered
                            .where((t) => !t.isCredit)
                            .fold<double>(0, (v, t) => v + t.amount),
                        mask: true),
                    size: 18,
                    color: p.error)
              ]))
            ])
          ])),
      field('', search, p,
          hint: s.tr('Search transactions, ID or amount',
              'লেনদেন, আইডি বা পরিমাণ অনুসন্ধান'),
          suffix: const Icon(Icons.search),
          onChanged: (_) => setState(() {})),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < 5; i++)
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: text(
                          [
                            s.tr('All Dates', 'সকল তারিখ'),
                            s.tr('Today', 'আজ'),
                            s.tr('Last 7 Days', 'গত ৭ দিন'),
                            s.tr('This Month', 'চলতি মাস'),
                            s.tr('Older', 'পূর্ববর্তী')
                          ][i],
                          size: 11),
                      selected: date == i,
                      onSelected: (_) => setState(() => date = i)))
          ])),
      tabs([
        s.tr('All Types', 'সকল ধরন'),
        s.tr('Money In (+)', 'জমা (+)'),
        s.tr('Money Out (-)', 'খরচ (-)')
      ], type, (v) => setState(() => type = v), p),
      DropdownButtonFormField<String>(
          initialValue: category,
          isExpanded: true,
          items: ['ALL', ...s.transactions.map((t) => t.categoryEn).toSet()]
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: text(
                      v == 'ALL' ? s.tr('All Categories', 'সকল বিভাগ') : v,
                      size: 12,
                      color: p.ink)))
              .toList(),
          onChanged: (v) => setState(() => category = v!),
          decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      Row(children: [
        Expanded(
            child: text('${filtered.length} ${s.tr('Transactions', 'লেনদেন')}',
                size: 12, color: p.muted)),
        link(s.tr('Reset Filters', 'ফিল্টার মুছুন'), () {
          setState(() {
            date = 0;
            type = 0;
            category = 'ALL';
            search.clear();
          });
        })
      ]),
      if (filtered.isEmpty)
        Padding(
            padding: const EdgeInsets.all(30),
            child: Center(
                child: stack([
              Icon(Icons.search_off, size: 48, color: p.muted),
              text(s.tr('No transactions found', 'কোনো লেনদেন পাওয়া যায়নি'),
                  color: p.muted)
            ], align: CrossAxisAlignment.center)))
      else
        panel(
            p,
            Column(children: [
              for (final t in filtered) ...[
                TransactionRow(
                    transaction: t,
                    state: s,
                    onTap: () => showReceipt(context, s, t)),
                Divider(height: 1, color: p.border)
              ]
            ])),
      secondary(s.tr('Export Statement', 'স্টেটমেন্ট এক্সপোর্ট করুন'), () {
        Clipboard.setData(ClipboardData(
            text: filtered
                .map((t) =>
                    '${t.txnId},${t.titleEn},${t.timeEn},${t.isCredit ? '+' : '-'}${t.amount}')
                .join('\n')));
        toast(context,
            s.tr('Statement copied to clipboard', 'স্টেটমেন্ট কপি করা হয়েছে'));
      }, p, icon: Icons.download),
    ]);
  }
}

Future<void> showReceipt(
        BuildContext context, ToriState s, TransactionItem t) async =>
    openPage<void>(context, s, s.tr('Transaction Details', 'লেনদেনের বিবরণ'),
        (ctx) {
      final p = Palette(s.dark);
      return pageBody([
        panel(
            p,
            stack([
              Center(
                  child: Icon(
                      t.isCredit ? Icons.call_received : Icons.call_made,
                      size: 44,
                      color: t.isCredit ? p.primary : p.error)),
              Center(
                  child: text(s.bengali ? t.titleBn : t.titleEn,
                      size: 20, color: p.ink, align: TextAlign.center)),
              Center(
                  child: text(s.money(t.amount, mask: true),
                      size: 30, color: t.isCredit ? p.primary : p.error)),
              Center(
                  child: pill(s.bengali ? t.statusBn : t.statusEn, p.primary)),
              Divider(color: p.border),
              infoRow(s.tr('Transaction ID', 'লেনদেন আইডি'), t.txnId, p),
              infoRow(s.tr('Date & Time', 'তারিখ ও সময়'),
                  s.bengali ? t.timeBn : t.timeEn, p),
              infoRow(s.tr('Category', 'বিভাগ'),
                  s.bengali ? t.categoryBn : t.categoryEn, p),
              if (t.note != null) infoRow(s.tr('Note', 'নোট'), t.note!, p)
            ])),
        secondary(s.tr('Copy Receipt', 'রশিদ কপি করুন'), () {
          Clipboard.setData(ClipboardData(
              text:
                  'TORI Bank\n${t.txnId}\n${t.titleEn}\n${s.money(t.amount)}\n${t.timeEn}'));
          toast(
              ctx, s.tr('Receipt copied to clipboard', 'রশিদ কপি করা হয়েছে'));
        }, p, icon: Icons.copy),
        primary(s.tr('Done', 'সম্পন্ন'), () => Navigator.pop(ctx))
      ]);
    });

Future<void> showProjectDetails(BuildContext context, ToriState s) async =>
    openPage<void>(context, s, s.tr('Project Details', 'প্রকল্পের বিবরণ'),
        (ctx) {
      final p = Palette(s.dark);
      return pageBody([
        text('Green Delta Agro Farm', size: 24, color: p.ink),
        Row(children: [
          Expanded(child: panel(p, infoRow('Funded', '75%', p))),
          hgap(),
          Expanded(child: panel(p, infoRow('Duration', '12 Months', p)))
        ]),
        text('Milestone Timeline', size: 18, color: p.ink),
        for (final milestone in [
          'Land Preparation',
          'Seed Procurement',
          'Planting',
          'Harvest'
        ])
          ListTile(
              leading: Icon(Icons.check_circle_outline, color: p.primary),
              title: text(milestone, color: p.ink)),
        text(
            'This project aims to expand organic farming in the Green Delta region using sustainable MFI financing.',
            color: p.muted),
        primary(s.tr('Invest Now', 'বিনিয়োগ করুন'), () {})
      ]);
    });
