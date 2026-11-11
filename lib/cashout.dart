import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dialogs.dart';
import 'services/cashout_service.dart';
import 'state.dart';
import 'ui.dart';

Future<void> showCashout(BuildContext context, ToriState state) async {
  await openPage<void>(
      context,
      state,
      state.tr('Branch Cash Out', 'শাখা থেকে ক্যাশ আউট'),
      (_) => CashoutPage(state: state));
  await state.loadDashboardData();
}

class CashoutPage extends StatefulWidget {
  final ToriState state;
  final CashoutService? service;
  final String? initialQr;
  const CashoutPage(
      {super.key, required this.state, this.service, this.initialQr});
  @override
  State<CashoutPage> createState() => _CashoutPageState();
}

class _CashoutPageState extends State<CashoutPage> {
  late final service = widget.service ?? CashoutService();
  final amount = TextEditingController(), pin = TextEditingController();
  Map<String, dynamic>? data, quote, uncertain;
  bool loading = true, busy = false;
  bool refreshing = false;
  String? code, error;
  Timer? timer;
  ToriState get s => widget.state;
  String get language => s.bengali ? 'bn' : 'en';

  @override
  void initState() {
    super.initState();
    code = widget.initialQr;
    load();
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!busy && !loading && data != null) load(silent: true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    amount.dispose();
    pin.dispose();
    if (widget.service == null) service.close();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    if (refreshing) return;
    refreshing = true;
    try {
      if (!silent)
        setState(() {
          loading = true;
          error = null;
        });
      final result = await service.load(language);
      if (!mounted) return;
      if (result['success'] == true) {
        final fresh = result['data'] as Map<String, dynamic>;
        var pending = await service.pending(fresh['customer_id']);
        var resolved = false;
        if (pending != null &&
            (fresh['requests'] as List)
                .any((r) => r['request_key'] == pending!['key'])) {
          await service.clear(fresh['customer_id']);
          pending = null;
          resolved = true;
        }
        if (!mounted) return;
        setState(() {
          data = fresh;
          uncertain = pending;
          loading = false;
          if (resolved) {
            quote = null;
            code = null;
            amount.clear();
            pin.clear();
          }
        });
      } else if (!silent) {
        setState(() {
          loading = false;
          error = result['message'];
        });
      }
    } finally {
      refreshing = false;
    }
  }

  Future<void> scan() async {
    final value = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CashoutScanner(bengali: s.bengali)));
    if (!mounted || value == null) return;
    setState(() {
      code = value;
      quote = null;
      error = null;
    });
  }

  Future<void> review() async {
    if (busy || code == null) return;
    final amountError = transactionAmountError(amount.text,
        data?['minimum_amount'], data?['maximum_amount'], s.bengali);
    if (amountError != null) {
      setState(() => error = amountError);
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });
    final result = await service.quote(code!, amount.text.trim(), language);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (result['success'] == true) {
        quote = result['data'];
        pin.clear();
      } else {
        error = result['message'];
      }
    });
  }

  Future<void> confirm() async {
    if (busy || !RegExp(r'^\d{6}$').hasMatch(pin.text)) {
      setState(
          () => error = s.tr('Enter your 6-digit PIN.', '৬ সংখ্যার পিন দিন।'));
      return;
    }
    final reviewed = uncertain?['quote_data'] ?? quote;
    if (reviewed == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.tr(
            'Confirm cash-out request?', 'ক্যাশ আউট অনুরোধ নিশ্চিত করবেন?')),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.tr('Branch', 'শাখা')}: ${reviewed['branch'] ?? ''}'),
                Text(
                    '${s.tr('Cash you receive', 'হাতে পাবেন')}: ৳ ${reviewed['amount']}'),
                Text('${s.tr('Charge', 'চার্জ')}: ৳ ${reviewed['fee']}'),
                Text(
                    '${s.tr('Total savings debit', 'সঞ্চয় থেকে মোট কাটবে')}: ৳ ${reviewed['total']}'),
                const SizedBox(height: 12),
                Text(s.tr(
                    'This amount will be held until the branch pays cash or the request is closed.',
                    'শাখা নগদ পরিশোধ করা বা অনুরোধ বন্ধ হওয়া পর্যন্ত এই টাকা সংরক্ষিত থাকবে।')),
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.tr('Go back', 'ফিরে যান'))),
          FilledButton(
              key: const Key('cashout-final-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(s.tr('Send request', 'অনুরোধ পাঠান'))),
        ],
      ),
    );
    if (!mounted) return;
    if (approved != true) {
      setState(() => busy = false);
      return;
    }
    final result = await service.create(
        data!['customer_id'], reviewed, pin.text, language);
    final pendingRequest = await service.pending(data!['customer_id']);
    if (!mounted) return;
    setState(() {
      busy = false;
      uncertain = pendingRequest;
      pin.clear();
      if (result['success'] == true) {
        quote = null;
        code = null;
        amount.clear();
      } else {
        error = result['message'];
      }
    });
    if (result['success'] == true) {
      toast(
          context,
          s.tr('Cash-out request sent to the branch.',
              'ক্যাশ আউট অনুরোধ শাখায় পাঠানো হয়েছে।'));
    }
    await load(silent: true);
  }

  Future<void> cancel(int id) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await service.cancel(id, language);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (result['success'] != true) error = result['message'];
    });
    await load(silent: true);
  }

  String status(String value) => switch (value) {
        'Pending' => s.tr('Waiting for branch', 'শাখার অপেক্ষায়'),
        'Accepted' => s.tr('Accepted — collect cash at counter',
            'গ্রহণ করা হয়েছে — কাউন্টার থেকে নগদ নিন'),
        'Completed' => s.tr('Completed', 'সম্পন্ন'),
        'Cancelled' => s.tr('Cancelled', 'বাতিল'),
        'Rejected' => s.tr('Rejected', 'প্রত্যাখ্যাত'),
        'Expired' => s.tr('Expired', 'মেয়াদ শেষ'),
        _ => value,
      };

  Widget summary(Map<String, dynamic> value, Palette p) => panel(
      p,
      stack([
        infoRow(s.tr('Branch', 'শাখা'), value['branch'] ?? '', p),
        infoRow(
            s.tr('Cash you receive', 'হাতে পাবেন'), '৳ ${value['amount']}', p),
        infoRow(s.tr('Charge', 'চার্জ'), '৳ ${value['fee']}', p),
        infoRow(s.tr('Total savings debit', 'সঞ্চয় থেকে মোট কাটবে'),
            '৳ ${value['total']}', p),
      ]));

  @override
  Widget build(BuildContext context) {
    final p = Palette(s.dark);
    if (loading) return const Center(child: CircularProgressIndicator());
    final reviewData = uncertain?['quote_data'] ?? quote;
    return pageBody([
      if (error != null) text(error!, color: p.error),
      if (data == null)
        primary(s.tr('Retry', 'আবার চেষ্টা করুন'), () => load()),
      if (data != null) ...[
        panel(
            p,
            stack([
              infoRow(s.tr('Savings balance', 'সঞ্চয় ব্যালেন্স'),
                  '৳ ${data!['balance']}', p),
              infoRow(
                  s.tr('Reserved for cash-out', 'ক্যাশ আউটের জন্য সংরক্ষিত'),
                  '৳ ${data!['held_balance']}',
                  p),
              infoRow(s.tr('Available balance', 'ব্যবহারযোগ্য ব্যালেন্স'),
                  '৳ ${data!['available_balance']}', p),
            ])),
        if (uncertain != null)
          text(
              s.tr(
                  'An earlier request needs confirmation. Refresh or retry it before creating another.',
                  'আগের অনুরোধের ফলাফল নিশ্চিত করা দরকার। নতুন অনুরোধের আগে রিফ্রেশ করুন অথবা সেটি আবার চেষ্টা করুন।'),
              color: p.error),
        if (data!['enabled'] == true && uncertain == null && quote == null) ...[
          text(
              s.tr(
                  'Per transaction: Tk ${data!['minimum_amount'] ?? '1.00'} – ${data!['maximum_amount']}',
                  'প্রতি লেনদেনে: ৳ ${data!['minimum_amount'] ?? '1.00'} – ${data!['maximum_amount']}'),
              color: p.muted),
          secondary(
              code == null
                  ? s.tr('Scan branch QR', 'শাখার কিউআর স্ক্যান করুন')
                  : s.tr('Scan another QR', 'অন্য কিউআর স্ক্যান করুন'),
              busy ? null : scan,
              p,
              icon: Icons.qr_code_scanner),
          field(s.tr('Cash-out amount', 'ক্যাশ আউটের পরিমাণ'), amount, p,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          primary(s.tr('Review cash-out', 'ক্যাশ আউট পর্যালোচনা করুন'),
              busy || code == null ? null : review,
              busy: busy),
        ] else if (data!['enabled'] != true && reviewData == null)
          text(
              s.tr('Cash-out is currently unavailable.',
                  'ক্যাশ আউট বর্তমানে বন্ধ আছে।'),
              color: p.muted),
        if (reviewData != null) ...[
          summary(Map<String, dynamic>.from(reviewData), p),
          text(
              s.tr(
                  'This amount will be held until the branch pays cash or the request is closed.',
                  'শাখা নগদ পরিশোধ করা বা অনুরোধ বন্ধ হওয়া পর্যন্ত এই টাকা সংরক্ষিত থাকবে।'),
              color: p.muted),
          TextField(
              key: const Key('cashout-pin'),
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
              uncertain != null
                  ? s.tr('Retry same request', 'একই অনুরোধ আবার চেষ্টা করুন')
                  : s.tr('Confirm cash-out', 'ক্যাশ আউট নিশ্চিত করুন'),
              busy ? null : confirm,
              busy: busy),
          if (uncertain == null)
            secondary(s.tr('Edit amount', 'পরিমাণ পরিবর্তন করুন'),
                busy ? null : () => setState(() => quote = null), p),
        ],
        secondary(s.tr('Refresh status', 'অবস্থা রিফ্রেশ করুন'),
            busy ? null : () => load(), p),
        text(s.tr('Recent cash-outs', 'সাম্প্রতিক ক্যাশ আউট'),
            size: 18, color: p.ink),
        for (final item in data!['requests'] as List)
          panel(
              p,
              stack([
                text(item['reference'], color: p.ink),
                text(status(item['status']),
                    color: item['status'] == 'Completed' ? p.primary : p.muted),
                infoRow(s.tr('Branch', 'শাখা'), item['branch'] ?? '', p),
                infoRow(s.tr('Cash / charge', 'নগদ / চার্জ'),
                    '৳ ${item['amount']} / ৳ ${item['fee']}', p),
                infoRow(s.tr('Total savings debit', 'সঞ্চয় থেকে মোট কাটবে'),
                    '৳ ${item['total']}', p),
                if (item['completed_at'] != null)
                  infoRow(s.tr('Paid on', 'পরিশোধের সময়'),
                      item['completed_at'], p),
                if (item['reason'] != null)
                  text(item['reason'], color: p.error),
                if (item['status'] == 'Pending')
                  secondary(s.tr('Cancel request', 'অনুরোধ বাতিল করুন'),
                      busy ? null : () => cancel(item['id']), p),
              ])),
      ],
    ]);
  }
}

class CashoutScanner extends StatefulWidget {
  final bool bengali;
  const CashoutScanner({super.key, required this.bengali});
  @override
  State<CashoutScanner> createState() => _CashoutScannerState();
}

class _CashoutScannerState extends State<CashoutScanner> {
  final controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool detected = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.bengali
                ? 'শাখার কিউআর স্ক্যান করুন'
                : 'Scan branch QR')),
        body: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (!detected && barcode.rawValue != null) {
                  detected = true;
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
            errorBuilder: (context, error) => Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(widget.bengali
                        ? 'ক্যামেরা খোলা যায়নি। ক্যামেরার অনুমতি পরীক্ষা করুন।'
                        : 'Unable to open camera. Check camera permissions.')))),
      );
}
