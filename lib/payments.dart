import 'send_money.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dashboard.dart';
import 'dialogs.dart';
import 'payment_security.dart';
import 'cashout.dart';

class PaymentsScreen extends StatefulWidget {
  final ToriState state;
  const PaymentsScreen({super.key, required this.state});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int step = 0, category = 0;
  bool busy = false;
  String? error;
  String? biller;
  late final TextEditingController recipient, amount, note;
  final otp = TextEditingController(), pin = TextEditingController();
  TransactionItem? receipt;
  ToriState get s => widget.state;
  Palette get p => Palette(s.dark);
  @override
  void initState() {
    super.initState();
    recipient = TextEditingController(text: s.recipient);
    amount = TextEditingController(text: s.amount.toStringAsFixed(0));
    note = TextEditingController(text: s.note);
  }

  @override
  void dispose() {
    for (final c in [recipient, amount, note, otp, pin]) c.dispose();
    super.dispose();
  }

  void next(int value) {
    if (value == 1 && s.channel == TransferChannel.TORI_ACCOUNT) {
      showSendMoney(context, s);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      step = value;
      error = null;
    });
  }

  void favorite(FavoriteContact f) {
    s.selectFavorite(f);
    if (s.channel == TransferChannel.TORI_ACCOUNT) {
      showSendMoney(context, s, initialRecipient: f.number);
      return;
    }
    recipient.text = f.number;
    next(2);
  }

  void back() {
    if (step == 0)
      s.navigate(AppNavTab.HOME);
    else
      next(step == 5 ? 0 : step - 1);
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  roundIcon(Icons.arrow_back, p, onTap: back),
                  hgap(12),
                  Expanded(
                      child: text(
                          [
                            s.tr(
                                'Payments & Transfers', 'পেমেন্ট ও ট্রান্সফার'),
                            s.tr('Select Recipient', 'প্রাপক নির্বাচন'),
                            s.tr('Enter Amount', 'পরিমাণ দিন'),
                            s.tr('Review Transfer', 'ট্রান্সফার পর্যালোচনা'),
                            s.tr('Verify & Pay', 'যাচাই ও পরিশোধ'),
                            s.tr('Payment Receipt', 'পেমেন্ট রশিদ')
                          ][step],
                          size: 18,
                          color: p.ink,
                          family: 'PlusJakartaSans')),
                  roundIcon(Icons.history, p,
                      onTap: () => showStatement(context, s)),
                  hgap(8),
                  roundIcon(Icons.qr_code_scanner, p,
                      onTap: () => showQrScanner(context, s))
                ])),
            if (step > 0 && step < 5)
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(children: [
                    for (int i = 1; i < 5; i++)
                      Expanded(
                          child: Column(children: [
                        CircleAvatar(
                            radius: 13,
                            backgroundColor: i <= step ? p.primary : p.raised,
                            child: i < step
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : text('$i',
                                    size: 11,
                                    color: i == step ? Colors.white : p.muted)),
                        gap(5),
                        text(
                            [
                              s.tr('Recipient', 'প্রাপক'),
                              s.tr('Amount', 'পরিমাণ'),
                              s.tr('Review', 'রিভিউ'),
                              s.tr('Verify', 'যাচাই')
                            ][i - 1],
                            size: 10,
                            color: p.muted)
                      ]))
                  ])),
            Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                            key: ValueKey(step),
                            child: switch (step) {
                              0 => hub(),
                              1 => recipientStep(),
                              2 => amountStep(),
                              3 => reviewStep(),
                              4 => securityStep(),
                              _ => receiptStep()
                            })))),
          ])));
  Widget source() => panel(
      p,
      Row(children: [
        Icon(Icons.account_balance_wallet, color: p.primary, size: 30),
        hgap(12),
        Expanded(
            child: stack([
          text(
              s.tr('Source: TORI Premium Savings',
                  'উৎস হিসাব (TORI প্রিমিয়াম সঞ্চয়)'),
              size: 11,
              color: p.muted),
          text('A/C •••• 4589', size: 13, color: p.ink)
        ], spacing: 4)),
        Flexible(
            child: stack([
          text(s.tr('Available Balance', 'ব্যবহারযোগ্য ব্যালেন্স'),
              size: 10, color: p.muted),
          text(s.money(s.balance, mask: true), size: 15, color: p.primary)
        ], spacing: 4, align: CrossAxisAlignment.end))
      ]),
      padding: 14);
  Widget hub() => stack([
        source(),
        hubAction(
            s.tr('Branch Cash Out', 'শাখা থেকে ক্যাশ আউট'),
            s.tr('Withdraw your Shomriddhi savings',
                'সমৃদ্ধি সঞ্চয় থেকে নগদ তুলুন'),
            Icons.payments,
            p.primary,
            () => showCashout(context, s)),
        tabs([
          s.tr('Transfer', 'ট্রান্সফার'),
          s.tr('Pay Bills', 'বিল পে'),
          s.tr('MFS / Cashout', 'এমএফএস')
        ], category, (v) => setState(() => category = v), p),
        if (category == 0) ...[
          tabs([
            'TORI Pay',
            'bKash / Nagad',
            s.tr('All Banks', 'ব্যাংক ট্রান্সফার')
          ], s.channel.index, (i) {
            s.channel = TransferChannel.values[i];
            s.changed();
          }, p),
          Row(children: [
            Expanded(
                child: hubAction(
                    s.tr('Send Money', 'টাকা পাঠান'),
                    s.tr('Send to another member', 'অন্য মেম্বারকে টাকা পাঠান'),
                    Icons.send,
                    p.primary,
                    () => showSendMoney(context, s))),
            hgap(10),
            Expanded(
                child: hubAction(
                    s.tr('MFI Loan Pay', 'কিস্তি পরিশোধ'),
                    s.tr('Auto Receipt', 'অটো রসিদ'),
                    Icons.handshake,
                    p.primary,
                    () => showMfiPayment(context, s)))
          ]),
          Row(children: [
            Expanded(
                child: hubAction(
                    s.tr('QR Scanner', 'কিউআর স্ক্যান'),
                    s.tr('Merchant Pay', 'মার্চেন্ট পে'),
                    Icons.qr_code_scanner,
                    const Color(0xFF0891B2),
                    () => showQrScanner(context, s))),
            hgap(10),
            Expanded(
                child: hubAction(
                    s.tr('Statement', 'লেনদেন বিবরণ'),
                    s.tr('E-Receipts', 'ই-রশিদ ডাউনলোড'),
                    Icons.receipt_long,
                    const Color(0xFFD97706),
                    () => showStatement(context, s)))
          ]),
          sectionTitle(s.tr('Saved Beneficiaries', 'প্রিয় প্রাপক ও সদস্য'), p,
              action: s.tr('See All', 'সব দেখুন'), onAction: () => next(1)),
          beneficiaries(),
        ],
        if (category == 1) ...[
          sectionTitle(
              s.tr('Utility Bill Payments', 'ইউটিলিটি বিল পেমেন্ট'), p),
          for (int row = 0; row < 3; row++)
            Row(children: [
              for (int col = 0; col < 2; col++) ...[
                if (col == 1) hgap(10),
                Expanded(
                    child: hubAction(
                        [
                          'DESCO Prepaid',
                          'DPDC Postpaid',
                          'Dhaka WASA',
                          'Titas Gas',
                          'Link3 Internet',
                          'School / College Fee'
                        ][row * 2 + col],
                        [
                          'Electricity',
                          'Electricity',
                          'Water',
                          'Gas',
                          'Internet',
                          'Education'
                        ][row * 2 + col],
                        const [
                          Icons.bolt,
                          Icons.electric_meter,
                          Icons.water_drop,
                          Icons.local_fire_department,
                          Icons.wifi,
                          Icons.school
                        ][row * 2 + col],
                        p.primary, () {
                  final i = row * 2 + col;
                  biller = [
                    'DESCO Prepaid',
                    'DPDC Postpaid',
                    'Dhaka WASA',
                    'Titas Gas',
                    'Link3 Internet',
                    'School / College Fee'
                  ][i];
                  s.channel = TransferChannel.BANK_TRANSFER;
                  recipient.text = [
                    '0102938491',
                    '2093841029',
                    '8947201948',
                    '4820194820',
                    '98201948',
                    'SCH-9482'
                  ][i];
                  s.recipientName = biller!;
                  s.recipient = recipient.text;
                  next(1);
                }))
              ]
            ])
        ],
        if (category == 2) ...[
          hubAction(
              'bKash / Nagad',
              s.tr('Send to mobile wallet', 'মোবাইল ওয়ালেটে পাঠান'),
              Icons.phone_android,
              p.error, () {
            s.channel = TransferChannel.BKASH_NAGAD;
            next(1);
          }),
          hubAction(
              s.tr('Branch Cash Out', 'শাখা থেকে ক্যাশ আউট'),
              s.tr('Scan branch QR to withdraw savings',
                  'শাখার কিউআর স্ক্যান করে সঞ্চয় তুলুন'),
              Icons.payments,
              p.primary, () {
            showCashout(context, s);
          })
        ],
        sectionTitle(s.tr('Recent Payments', 'সাম্প্রতিক পেমেন্ট'), p,
            action: s.tr('View All', 'সব দেখুন'),
            onAction: () => showStatement(context, s)),
        panel(
            p,
            Column(children: [
              for (final t in s.transactions.where((t) => !t.isCredit).take(3))
                TransactionRow(
                    transaction: t,
                    state: s,
                    onTap: () => showReceipt(context, s, t))
            ]))
      ], spacing: 16);
  Widget hubAction(String title, String caption, IconData icon, Color color,
          VoidCallback onTap) =>
      InkWell(
          onTap: onTap,
          child: panel(
              p,
              stack([
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 22)),
                text(title, size: 14, color: p.ink),
                text(caption, size: 10, color: p.muted)
              ], spacing: 8),
              radius: 16));
  Widget beneficiaries() => SizedBox(
      height: 82,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        SizedBox(
            width: 70,
            child: Column(children: [
              roundIcon(Icons.add, p, onTap: () => next(1), size: 48),
              gap(6),
              text(s.tr('New Send', 'নতুন প্রাপক'), size: 10, color: p.muted)
            ])),
        for (final f in s.favorites)
          SizedBox(
              width: 74,
              child: InkWell(
                  onTap: () => favorite(f),
                  child: Column(children: [
                    CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Color(f.badgeColorHex).withValues(alpha: .12),
                        child: text(f.initials ?? f.shortName[0],
                            color: Color(f.badgeColorHex), size: 17)),
                    gap(6),
                    text(f.shortName, size: 11, color: p.ink, lines: 1)
                  ])))
      ]));
  Widget recipientStep() => stack([
        source(),
        panel(
            p,
            stack([
              text(s.tr('Who are you sending to?', 'কাকে টাকা পাঠাবেন?'),
                  size: 20, color: p.ink),
              tabs(['TORI Pay', 'bKash / Nagad', 'All Banks'], s.channel.index,
                  (i) {
                s.channel = TransferChannel.values[i];
                s.changed();
              }, p),
              field(
                  biller ??
                      s.tr('Mobile / Account Number', 'মোবাইল / হিসাব নম্বর'),
                  recipient,
                  p,
                  hint: '01719 283741',
                  keyboard: TextInputType.phone, onChanged: (v) {
                s.updateRecipient(v);
                setState(() {});
              }),
              if (s.recipientName.isNotEmpty)
                pill('✓ ${s.recipientName}', p.primary),
              text(
                  s.tr('Verify recipient details before continuing.',
                      'এগিয়ে যাওয়ার আগে প্রাপকের তথ্য যাচাই করুন।'),
                  size: 11,
                  color: p.muted)
            ])),
        beneficiaries(),
        primary(
            s.tr('Continue to Amount', 'পরবর্তী: পরিমাণ দিন'),
            recipient.text.trim().length >= 8
                ? () {
                    s.recipient = recipient.text;
                    next(2);
                  }
                : null)
      ]);
  Widget amountStep() => stack([
        source(),
        panel(
            p,
            stack([
              text(s.tr('Enter Amount', 'পরিমাণ লিখুন'),
                  size: 20, color: p.ink),
              infoRow(s.tr('To', 'প্রাপক'),
                  s.recipientName.isEmpty ? s.recipient : s.recipientName, p),
              TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    s.amount = double.tryParse(v) ?? 0;
                    setState(() {});
                  },
                  style: font(36, color: p.ink, family: 'PlusJakartaSans'),
                  decoration: InputDecoration(
                      prefixText: '৳ ',
                      hintText: '0.00',
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: p.border)))),
              Wrap(spacing: 8, children: [
                for (final v in [500, 1000, 5000, 10000])
                  ActionChip(
                      label: text('+$v', size: 12, color: p.primary),
                      onPressed: () {
                        s.amount = (double.tryParse(amount.text) ?? 0) + v;
                        amount.text = s.amount.toStringAsFixed(0);
                        setState(() {});
                      })
              ]),
              field(s.tr('Transfer Note (Optional)', 'নোট (ঐচ্ছিক)'), note, p,
                  onChanged: (v) => s.note = v),
              infoRow(s.tr('Transfer Fee', 'ট্রান্সফার ফি'), '৳ 0.00', p,
                  valueColor: p.primary)
            ])),
        primary(
            s.tr('Review Transfer', 'রিভিউ দেখুন'),
            (double.tryParse(amount.text) ?? 0) > 0 &&
                    (double.tryParse(amount.text) ?? 0) <= s.balance
                ? () {
                    s.amount = double.parse(amount.text);
                    s.note = note.text;
                    next(3);
                  }
                : null)
      ]);
  Widget reviewStep() => stack([
        panel(
            p,
            stack([
              Center(
                  child: Icon(Icons.verified_user_outlined,
                      size: 44, color: p.primary)),
              Center(
                  child: text(s.tr('Review Transfer', 'ট্রান্সফার পর্যালোচনা'),
                      size: 20, color: p.ink)),
              Center(child: text(s.money(s.amount), size: 32, color: p.ink)),
              Divider(color: p.border),
              infoRow(s.tr('Recipient', 'প্রাপক'),
                  s.recipientName.isEmpty ? s.recipient : s.recipientName, p),
              infoRow(
                  s.tr('Account / Mobile', 'হিসাব / মোবাইল'), s.recipient, p),
              infoRow(s.tr('Channel', 'মাধ্যম'), s.channelName, p),
              infoRow(s.tr('Amount', 'পরিমাণ'), s.money(s.amount), p),
              infoRow(s.tr('Fee', 'ফি'), '৳ 0.00', p),
              infoRow(s.tr('Total Debit', 'মোট খরচ'), s.money(s.amount), p),
              infoRow(s.tr('Remaining Balance', 'অবশিষ্ট ব্যালেন্স'),
                  s.money(s.balance - s.amount), p),
              if (s.note.isNotEmpty) infoRow(s.tr('Note', 'নোট'), s.note, p)
            ])),
        primary(s.tr('Proceed to Verify', 'নিশ্চিত করুন ও এগিয়ে যান'),
            () => next(4))
      ]);
  Widget securityStep() => PaymentSecurityPanel(
      state: s, onAuthorized: () => showBackendUnavailable(context, s));
  Widget receiptStep() => stack([
        panel(
            p,
            stack([
              const Center(
                  child: Icon(Icons.check_circle,
                      color: Color(0xFF10B981), size: 68)),
              Center(
                  child: text(
                      s.tr('Transfer Successful!', 'স্থানান্তর সফল হয়েছে!'),
                      size: 22,
                      color: p.ink)),
              Center(child: text(s.money(s.amount), size: 32, color: p.ink)),
              infoRow('Transaction ID', receipt?.txnId ?? '', p),
              infoRow(s.tr('Recipient', 'প্রাপক'),
                  s.recipientName.isEmpty ? s.recipient : s.recipientName, p),
              infoRow(s.tr('Account', 'হিসাব'), s.recipient, p),
              infoRow(s.tr('Channel', 'মাধ্যম'), s.channelName, p),
              infoRow(s.tr('Remaining Balance', 'অবশিষ্ট ব্যালেন্স'),
                  s.money(s.balance), p)
            ])),
        secondary(s.tr('Share Receipt', 'রশিদ শেয়ার করুন'), () {
          Clipboard.setData(ClipboardData(
              text:
                  'TORI Bank Receipt #${receipt?.txnId} - ${s.money(s.amount)} sent to ${s.recipientName}'));
          toast(context,
              s.tr('Receipt copied to clipboard', 'রশিদ কপি করা হয়েছে'));
        }, p, icon: Icons.share),
        primary(s.tr('Done', 'সম্পন্ন'), () {
          s.recipient = '';
          s.recipientName = '';
          s.amount = 0;
          s.note = '';
          recipient.clear();
          amount.clear();
          note.clear();
          otp.clear();
          pin.clear();
          next(0);
        })
      ]);
}
