import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dashboard.dart';
import 'dialogs.dart';

class AccountsScreen extends StatelessWidget {
  final ToriState state;
  const AccountsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state, p = Palette(s.dark);
    final filtered = s.accounts.where((a) => switch (s.accountFilter) {
          AccountCategory.ALL => true,
          AccountCategory.SAVINGS => a.type == AccountType.SAVINGS_CURRENT,
          AccountCategory.DEPOSIT => a.type == AccountType.SHARIAH_DPS ||
              a.type == AccountType.FIXED_DEPOSIT_FDR,
          AccountCategory.LOANS => a.type == AccountType.MFI_LOAN
        });
    return Column(children: [
      Container(
          decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.border, width: .5))),
          child: SafeArea(
              bottom: false,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(
                        child: stack([
                      text(s.tr('Accounts & Holdings', 'হিসাব ও আমানত'),
                          size: 20, color: p.ink, family: 'PlusJakartaSans'),
                      text(
                          s.tr('Consolidated portfolio across banking & MFI',
                              'ব্যাংকিং ও ক্ষুদ্রঋণের সমন্বিত পোর্টফোলিও'),
                          size: 11.5,
                          color: p.muted)
                    ], spacing: 3)),
                    roundIcon(
                        s.hidden ? Icons.visibility_off : Icons.visibility, p,
                        onTap: () {
                      s.hidden = !s.hidden;
                      s.changed();
                    })
                  ])))),
      Expanded(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
              child: stack([
                ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: panel(
                        p,
                        Column(children: [
                          Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                Color(0xFF0D9488),
                                Color(0xFF2DD4BF),
                                Color(0xFF10B981)
                              ]))),
                          Padding(
                              padding: const EdgeInsets.all(18),
                              child: stack([
                                Row(children: [
                                  Expanded(
                                      child: text(
                                          s.tr('NET POSITION (BDT)',
                                              'নেট আর্থিক অবস্থান (টাকা)'),
                                          size: 11,
                                          color: p.muted,
                                          spacing: .8)),
                                  pill(
                                      s.tr('● Healthy • 82.9% Net',
                                          '● শক্তিশালী • ৮২.৯% নিট'),
                                      p.primary,
                                      size: 10)
                                ]),
                                text(
                                    s.money(s.assets - s.liabilities,
                                        mask: true),
                                    size: 28,
                                    color: p.ink),
                                Divider(color: p.border),
                                Row(children: [
                                  Expanded(
                                      child: stack([
                                    text(s.tr('● Total Assets', '● মোট সম্পদ'),
                                        size: 11, color: p.muted),
                                    text(
                                        s.money(s.assets,
                                            mask: true, decimals: false),
                                        size: 17,
                                        color: p.primary)
                                  ], spacing: 4)),
                                  Container(
                                      height: 36, width: 1, color: p.border),
                                  hgap(16),
                                  Expanded(
                                      child: stack([
                                    text(
                                        s.tr('● Total Liability', '● মোট দায়'),
                                        size: 11,
                                        color: p.muted),
                                    text(
                                        s.money(s.liabilities,
                                            mask: true, decimals: false),
                                        size: 17,
                                        color: p.error)
                                  ], spacing: 4))
                                ])
                              ]))
                        ]),
                        padding: 0)),
                panel(
                    p,
                    Column(children: [
                      for (int row = 0; row < 2; row++) ...[
                        if (row == 1) gap(12),
                        Row(children: [
                          for (int i = row * 3; i < row * 3 + 3; i++)
                            Expanded(
                                child: ServiceTile(
                                    label: [
                                      s.tr('Transfer', 'স্থানান্তর'),
                                      s.tr('Add Money', 'টাকা যোগ'),
                                      s.tr('Pay Obligation', 'কিস্তি পরিশোধ'),
                                      s.tr('Statement', 'স্টেটমেন্ট'),
                                      s.tr('Open Scheme', 'নতুন স্কিম'),
                                      s.tr('QR Pay', 'কিউআর পে')
                                    ][i],
                                    icon: const [
                                      Icons.swap_horiz,
                                      Icons.add_card,
                                      Icons.receipt_long,
                                      Icons.description,
                                      Icons.savings,
                                      Icons.qr_code_scanner
                                    ][i],
                                    color: const [
                                      Color(0xFF0D9488),
                                      Color(0xFF0284C7),
                                      Color(0xFFE11D48),
                                      Color(0xFF64748B),
                                      Color(0xFF7C3AED),
                                      Color(0xFFD97706)
                                    ][i],
                                    p: p,
                                    onTap: () {
                                      switch (i) {
                                        case 0:
                                          s.navigate(AppNavTab.PAYMENTS);
                                        case 1:
                                          showAddMoney(context, s);
                                        case 2:
                                          showMfiPayment(context, s);
                                        case 3:
                                          showStatement(context, s);
                                        case 4:
                                          showOpenDeposit(context, s);
                                        case 5:
                                          showQrScanner(context, s);
                                      }
                                    }))
                        ])
                      ]
                    ])),
                tabs([
                  s.tr('All', 'সকল'),
                  s.tr('Savings', 'সঞ্চয়ী'),
                  'DPS/FDR',
                  s.tr('Loans', 'ঋণসমূহ')
                ], s.accountFilter.index, (i) {
                  s.accountFilter = AccountCategory.values[i];
                  s.changed();
                }, p),
                for (final a in filtered) accountCard(context, a, s, p),
                gap(8),
                sectionTitle(
                    s.tr('Recent Transactions', 'সাম্প্রতিক লেনদেন'), p,
                    action: s.tr('View Full History', 'সম্পূর্ণ ইতিহাস'),
                    onAction: () => showStatement(context, s)),
                panel(
                    p,
                    Column(children: [
                      for (final t in s.transactions.take(4))
                        TransactionRow(
                            transaction: t,
                            state: s,
                            onTap: () => showReceipt(context, s, t))
                    ])),
                panel(
                    p,
                    Row(children: [
                      Icon(Icons.calendar_month, color: p.error),
                      hgap(12),
                      Expanded(
                          child: stack([
                        text(s.tr('Upcoming Installment', 'আসন্ন কিস্তি'),
                            size: 13, color: p.ink),
                        text('৳ 12,500 • 15 Oct', size: 11, color: p.muted)
                      ], spacing: 4)),
                      link(s.tr('Pay Now', 'পরিশোধ করুন'),
                          () => showMfiPayment(context, s),
                          color: p.error)
                    ]),
                    color: p.error.withValues(alpha: .06)),
                secondary(
                    s.tr('+ Open New DPS or FDR Account',
                        '+ নতুন ডিপিএস বা এফডিআর খুলুন'),
                    () => showOpenDeposit(context, s),
                    p),
              ])))
    ]);
  }

  Widget accountCard(
      BuildContext context, AccountItem a, ToriState s, Palette p) {
    final i = a.type.index,
        color = i == 3
            ? p.error
            : i == 2
                ? const Color(0xFF0284C7)
                : const Color(0xFF0D9488);
    return panel(
        p,
        stack([
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: .2))),
                child: Icon(
                    const [
                      Icons.account_balance_wallet,
                      Icons.savings,
                      Icons.account_balance,
                      Icons.request_quote
                    ][i],
                    color: color,
                    size: 22)),
            hgap(12),
            Expanded(
                child: stack([
              text(s.bengali ? a.titleBn : a.titleEn, size: 14, color: p.ink),
              text(a.accountNumber,
                  size: 11, color: p.muted, family: 'monospace')
            ], spacing: 3)),
            pill(i == 0 ? 'ACTIVE' : a.tagText, color)
          ]),
          Row(children: [
            Expanded(
                child: stack([
              text(
                  [
                    s.tr('AVAILABLE BALANCE', 'ব্যবহারযোগ্য ব্যালেন্স'),
                    s.tr('TOTAL DEPOSITED', 'মোট জমা করা হয়েছে'),
                    s.tr('PRINCIPAL AMOUNT', 'মূল আমানত পরিমাণ'),
                    s.tr('OUTSTANDING LOAN', 'বকেয়া ঋণ পরিমাণ')
                  ][i],
                  size: 10,
                  color: p.muted),
              text(s.money(a.balance, mask: true), size: 24, color: p.ink)
            ], spacing: 3)),
            if (i == 0)
              link(s.tr('Statement ↗', 'স্টেটমেন্ট ↗'),
                  () => showStatement(context, s),
                  color: color),
            if (i == 2) pill(a.interestRate ?? '8.5% p.a.', color),
            if (i == 3)
              pill(s.tr('Due in 6 Days', '৬ দিনের মধ্যে প্রদেয়'), color)
          ]),
          if (i == 1) ...[
            infoRow(s.tr('Monthly Deposit', 'মাসিক জমা'),
                s.bengali ? a.subtitleBn : a.subtitleEn, p),
            infoRow(s.tr('Installments', 'কিস্তি'),
                '${a.installmentsCompleted} / ${a.totalInstallments}', p),
            infoRow(s.tr('Accumulation progress', 'সঞ্চয় অগ্রগতি'), '66%', p,
                valueColor: color),
            ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                    value: .66,
                    minHeight: 6,
                    color: color,
                    backgroundColor: p.raised))
          ],
          if (i == 2) ...[
            infoRow(s.tr('Maturity Date', 'মেয়াদ পূর্তির তারিখ'),
                a.maturityDateEn ?? '', p),
            infoRow(s.tr('Accrued Profit', 'অর্জিত মুনাফা'),
                s.money(a.accruedProfit ?? 0, mask: true), p,
                valueColor: p.primary),
            if (a.isAutoRenewal)
              pill(s.tr('Auto Renewal Enabled', 'স্বয়ংক্রিয় নবায়ন চালু'),
                  p.primary)
          ],
          if (i == 3) ...[
            infoRow(s.tr('Sanctioned Amount', 'অনুমোদিত পরিমাণ'),
                s.money(a.sanctionedAmount ?? 0, mask: true), p),
            infoRow(s.tr('Next Installment', 'পরবর্তী কিস্তি'),
                s.money(a.nextInstallmentAmount ?? 0, mask: true), p),
            infoRow(s.tr('Next Due Date', 'পরবর্তী প্রদেয় তারিখ'),
                (s.bengali ? a.nextDueDateBn : a.nextDueDateEn) ?? '', p),
            LinearProgressIndicator(
                value: a.repaidPercent / 100,
                color: p.primary,
                backgroundColor: p.raised),
            primary(s.tr('Pay Installment', 'কিস্তি পরিশোধ করুন'),
                () => showMfiPayment(context, s),
                height: 44)
          ]
        ], spacing: 14),
        radius: 18);
  }
}
