import 'kyc_access.dart';
import 'cashout.dart' show CashoutScanner;
import 'services/beneficiary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state.dart';
import 'dialogs.dart';
import 'ui.dart';
import 'services/send_money_service.dart';

Future<void> showSendMoney(BuildContext context, ToriState state,
    {String? initialRecipient, int? recipientId}) async {
  if (state.isAgent) {
    await showAgentMoney(context, state, 'agent_cashin',
        initialRecipient: initialRecipient, recipientId: recipientId);
    return;
  }
  await openPage<void>(
      context,
      state,
      state.tr('Send Money', 'টাকা পাঠান'),
      (_) => SendMoneyPage(
          state: state,
          initialRecipient: initialRecipient,
          recipientId: recipientId));
  await state.loadDashboardData();
}

Future<void> showAgentMoney(BuildContext context, ToriState state, String kind,
    {String? initialRecipient, int? recipientId}) async {
  await openPage<void>(
      context,
      state,
      kind == 'agent_cashin'
          ? state.tr('Member Cash-in', 'মেম্বার ক্যাশ ইন')
          : state.tr('Agent Cash-out', 'এজেন্ট ক্যাশ আউট'),
      (_) => SendMoneyPage(
          state: state,
          kind: kind,
          initialRecipient: initialRecipient,
          recipientId: recipientId));
  await state.loadDashboardData();
}

class SendMoneyPage extends StatefulWidget {
  final ToriState state;
  final String? kind;
  final SendMoneyService? service;
  final String? initialRecipient;
  final int? recipientId;
  const SendMoneyPage(
      {super.key,
      required this.state,
      this.service,
      this.kind,
      this.initialRecipient,
      this.recipientId});
  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  late final service = widget.service ??
      (widget.kind == null
          ? SendMoneyService()
          : AgentMoneyService(widget.kind!));
  final recipient = TextEditingController(),
      amount = TextEditingController(),
      pin = TextEditingController();
  Map<String, dynamic>? data, quote, pending;
  bool busy = false, loading = true;
  String? error, receipt;
  int? selectedRecipient, completedRecipient;
  ToriState get s => widget.state;
  String get lang => s.bengali ? 'bn' : 'en';
  @override
  void initState() {
    super.initState();
    recipient.text = widget.initialRecipient ?? '';
    selectedRecipient = widget.recipientId;
    load();
  }

  @override
  void dispose() {
    recipient.dispose();
    amount.dispose();
    pin.dispose();
    if (widget.service == null) service.close();
    super.dispose();
  }

  Future<void> load() async {
    final result = await service.load(lang);
    if (!mounted) return;
    if (result['success'] == true) {
      final next = Map<String, dynamic>.from(result['data']);
      var saved = await service.pending(next['customer_id']);
      if (saved != null) {
        for (final row in next['transfers'] as List) {
          if (row['request_key'] == saved!['key']) {
            await service.clear(next['customer_id']);
            saved = null;
            receipt = row['reference'];
            completedRecipient = row['recipient_id'];
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        data = next;
        pending = saved;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error = result['message'];
      });
    }
  }

  Future<void> review() async {
    if (busy || pending != null) return;
    final amountError = transactionAmountError(amount.text,
        data?['minimum_amount'], data?['maximum_amount'], s.bengali);
    if (amountError != null) {
      setState(() => error = amountError);
      return;
    }

    setState(() {
      busy = true;
      error = null;
      receipt = null;
    });
    final result = await service.quote(
        recipient.text.trim(), amount.text.trim(), lang,
        recipientId: selectedRecipient);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (result['success'] == true) {
        quote = Map<String, dynamic>.from(result['data']);
        pin.clear();
      } else {
        error = result['message'];
      }
    });
  }

  Future<void> send() async {
    if (busy) return;
    if (!RegExp(r'^\d{6}$').hasMatch(pin.text)) {
      setState(
          () => error = s.tr('Enter your 6-digit PIN.', '৬ সংখ্যার পিন দিন।'));
      return;
    }
    final reviewed = pending?['quote_data'] ?? quote;
    if (reviewed == null || data == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              title: Text(widget.kind == null
                  ? s.tr('Send money to this member?',
                      'এই মেম্বারকে টাকা পাঠাবেন?')
                  : widget.kind == 'agent_cashin'
                      ? s.tr('Confirm Member Cash-in?',
                          'মেম্বার ক্যাশ ইন নিশ্চিত করবেন?')
                      : s.tr('Confirm Agent Cash-out?',
                          'এজেন্ট ক্যাশ আউট নিশ্চিত করবেন?')),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${reviewed['recipient_name']} / ${reviewed['recipient_member_no'] ?? ''}'),
                    Text(
                        '${widget.kind == 'agent_cashout' ? s.tr('Cash you receive', 'আপনি নগদ পাবেন') : s.tr('Recipient receives', 'প্রাপক পাবেন')}: ৳ ${reviewed['amount']}'),
                    Text('${s.tr('Charge', 'চার্জ')}: ৳ ${reviewed['fee']}'),
                    Text(
                        '${s.tr('Total savings debit', 'সঞ্চয় থেকে মোট কাটবে')}: ৳ ${reviewed['total']}'),
                    const SizedBox(height: 12),
                    if (widget.kind != null)
                      Text(widget.kind == 'agent_cashin'
                          ? s.tr(
                              'Confirm only after receiving cash from the member.',
                              'মেম্বারের নগদ টাকা পাওয়ার পর নিশ্চিত করুন।')
                          : s.tr(
                              'You will receive the principal amount in cash from the agent. Your PIN confirms immediate payment.',
                              'এজেন্টের কাছ থেকে মূল টাকা নগদ পাবেন। আপনার পিনে সঙ্গে সঙ্গে পেমেন্ট হবে।')),
                    Text(s.tr(
                        'Check the recipient carefully. The transfer completes immediately.',
                        'প্রাপকের তথ্য ভালোভাবে দেখুন। ট্রান্সফার সঙ্গে সঙ্গে সম্পন্ন হবে।')),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.tr('Go back', 'ফিরে যান'))),
                FilledButton(
                    key: const Key('send-money-final'),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(widget.kind == null
                        ? s.tr('Send now', 'এখন পাঠান')
                        : s.tr('Confirm now', 'এখন নিশ্চিত করুন')))
              ],
            ));
    if (!mounted) return;
    if (approved != true) {
      setState(() => busy = false);
      return;
    }
    final result = await service.create(data!['customer_id'],
        Map<String, dynamic>.from(reviewed), pin.text, lang);
    final saved = await service.pending(data!['customer_id']);
    if (!mounted) return;
    setState(() {
      busy = false;
      pending = saved;
      pin.clear();
      if (result['success'] == true) {
        receipt = result['data']['reference'];
        completedRecipient =
            result['data']['recipient_id'] ?? reviewed['recipient_id'];
        selectedRecipient = null;
        quote = null;
        recipient.clear();
        amount.clear();
      } else {
        error = result['message'];
        if (result['uncertain'] != true) quote = null;
      }
    });
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette(s.dark);
    final reviewed = pending?['quote_data'] ?? quote;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (data != null && data!['kyc_approved'] == false) {
      return KycAccessNotice(
          state: s, status: data!['kyc_status'] ?? 'Not submitted');
    }
    return pageBody([
      if (error != null) text(error!, color: p.error),
      if (receipt != null)
        panel(
            p,
            text(
                '${s.tr('Transfer completed', 'ট্রান্সফার সম্পন্ন হয়েছে')}\n$receipt',
                color: p.primary)),
      if (widget.kind == null && receipt != null && completedRecipient != null)
        TextButton.icon(
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(s.tr('Add to Quick Send', 'Quick Send-এ যোগ করুন')),
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final favourites = BeneficiaryService();
                    final result =
                        await favourites.save(completedRecipient!, '', lang);
                    favourites.close();
                    if (!mounted) return;
                    setState(() => busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result['success'] == true
                            ? s.tr('Saved in Quick Send',
                                'Quick Send-এ রাখা হয়েছে')
                            : result['message'] ?? 'Unable to save')));
                  }),
      if (data != null) ...[
        if (widget.kind == 'agent_cashin' && data!['agent'] != null)
          SelectableText(
              '${s.tr('Your Agent code', 'আপনার এজেন্ট কোড')}: ${data!['agent']['code']}'),
        if (data!['transaction_window']?['blocked'] == true)
          text(data!['transaction_window']['message'] ?? '', color: p.error),
        text(
            '${s.tr('Available savings', 'ব্যবহারযোগ্য সঞ্চয়')}: ৳ ${data!['available_balance']}',
            size: 18,
            color: p.ink),
        if (pending != null)
          text(
              s.tr(
                  'An earlier transfer needs confirmation. Refresh or retry the same request.',
                  'আগের ট্রান্সফারের ফলাফল নিশ্চিত করতে রিফ্রেশ করুন অথবা একই অনুরোধ আবার চেষ্টা করুন।'),
              color: p.error),
        if (reviewed == null && data!['enabled'] == true) ...[
          text(
              s.tr(
                  'Per transaction: Tk ${data!['minimum_amount'] ?? '1.00'} – ${data!['maximum_amount'] ?? '10000000.00'}',
                  'প্রতি লেনদেনে: ৳ ${data!['minimum_amount'] ?? '1.00'} – ${data!['maximum_amount'] ?? '10000000.00'}'),
              color: p.muted),
          if (widget.kind == 'agent_cashout')
            TextButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(s.tr('Scan Agent QR', 'এজেন্ট QR স্ক্যান করুন')),
                onPressed: busy
                    ? null
                    : () async {
                        final code = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CashoutScanner(
                                    bengali: s.bengali,
                                    title: s.tr('Scan Agent QR',
                                        'এজেন্ট QR স্ক্যান করুন'))));
                        if (!mounted || code == null) return;
                        setState(() {
                          recipient.text = code;
                          selectedRecipient = null;
                        });
                      }),
          field(
              widget.kind == 'agent_cashout'
                  ? s.tr('Agent code, mobile or Member ID',
                      'এজেন্ট কোড, মোবাইল বা মেম্বার আইডি')
                  : s.tr('Recipient mobile number or Member ID',
                      'প্রাপকের মোবাইল নম্বর অথবা মেম্বার আইডি'),
              recipient,
              p,
              onChanged: (_) => selectedRecipient = null),
          field(s.tr('Amount', 'পরিমাণ'), amount, p,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          primary(s.tr('Review transfer', 'ট্রান্সফার পর্যালোচনা করুন'),
              busy ? null : review,
              busy: busy),
        ],
        if (data!['enabled'] != true && reviewed == null)
          text(
              s.tr('This service is currently unavailable.',
                  'এই সেবাটি বর্তমানে বন্ধ আছে।'),
              color: p.muted),
        if (reviewed != null) ...[
          panel(
              p,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                infoRow(s.tr('Recipient', 'প্রাপক'),
                    reviewed['recipient_name'] ?? '', p),
                infoRow(s.tr('Member ID', 'মেম্বার আইডি'),
                    reviewed['recipient_member_no'] ?? '', p),
                infoRow(
                    widget.kind == 'agent_cashout'
                        ? s.tr('Cash you receive', 'আপনি নগদ পাবেন')
                        : s.tr('Recipient receives', 'প্রাপক পাবেন'),
                    '৳ ${reviewed['amount']}',
                    p),
                infoRow(s.tr('Charge', 'চার্জ'), '৳ ${reviewed['fee']}', p),
                infoRow(s.tr('Total savings debit', 'সঞ্চয় থেকে মোট কাটবে'),
                    '৳ ${reviewed['total']}', p),
              ])),
          TextField(
              key: const Key('send-money-pin'),
              controller: pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6)
              ],
              decoration: InputDecoration(
                  labelText: s.tr('Your 6-digit PIN', 'আপনার ৬ সংখ্যার পিন'))),
          primary(
              pending != null
                  ? s.tr('Retry same request', 'একই অনুরোধ আবার চেষ্টা করুন')
                  : s.tr('Confirm transfer', 'ট্রান্সফার নিশ্চিত করুন'),
              busy ? null : send,
              busy: busy),
          if (pending == null)
            secondary(
                s.tr('Edit transfer', 'ট্রান্সফার পরিবর্তন করুন'),
                busy
                    ? null
                    : () => setState(() {
                          quote = null;
                          pin.clear();
                        }),
                p),
        ],
        text(s.tr('Recent transfers', 'সাম্প্রতিক ট্রান্সফার'),
            size: 18, color: p.ink),
        for (final row in data!['transfers'] as List)
          panel(
              p,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                text(
                    '${row['direction'] == 'sent' ? s.tr('Sent to', 'পাঠিয়েছেন') : s.tr('Received from', 'পেয়েছেন')} ${row['name'] ?? ''}',
                    color: p.ink),
                text(
                    '${row['reference']}\n৳ ${row['amount']} | ${s.tr('Charge', 'চার্জ')}: ৳ ${row['fee']}\n${row['created_at']}',
                    color: p.muted),
              ])),
      ],
      secondary(
          s.tr('Refresh status', 'অবস্থা রিফ্রেশ করুন'), busy ? null : load, p),
    ]);
  }
}
