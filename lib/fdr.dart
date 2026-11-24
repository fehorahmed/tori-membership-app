import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/fdr_service.dart';
import 'services/send_money_service.dart';
import 'state.dart';

Future<void> showFdr(BuildContext context, ToriState state) async {
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FdrPage(state: state)));
  await state.loadDashboardData();
}

class FdrPage extends StatefulWidget {
  final ToriState state;
  final FdrService? service;
  const FdrPage({super.key, required this.state, this.service});
  @override
  State<FdrPage> createState() => _FdrPageState();
}

class _FdrPageState extends State<FdrPage> {
  late final FdrService api = widget.service ?? FdrService();
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.service == null) api.close();
    super.dispose();
  }

  Future<void> load() async {
    final r = await api.request('');
    if (!mounted) return;
    setState(() {
      loading = false;
      data = r['success'] == true ? Map<String, dynamic>.from(r['data']) : data;
      error = r['success'] == true ? null : r['message'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
        appBar: AppBar(
            title: Text(s.tr('Fixed Deposit (FDR)', 'স্থায়ী আমানত (FDR)'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  if (data != null) ...[
                    Text('Available savings: ৳ ${data!['available_balance']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (data!['kyc_approved'] != true)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                              'Approved KYC is required to open or request encashment of an FDR.',
                              style: TextStyle(color: Colors.red))),
                    const SizedBox(height: 16),
                    const Text('My FDR accounts',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if ((data!['accounts'] as List).isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No FDR account yet.')),
                    for (final a in data!['accounts'])
                      Card(
                          child: ListTile(
                              title: Text('${a['fdr_no']} · ${a['status']}'),
                              subtitle: Text(
                                  '${a['scheme']?['name'] ?? 'FDR'}\nPrincipal: ৳ ${a['principal_amount']}\nMaturity: ${a['maturity_date']}'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => FdrDetails(
                                            api: api,
                                            id: a['id'],
                                            kyc: data!['kyc_approved'] ==
                                                true)));
                                load();
                              })),
                    const SizedBox(height: 20),
                    const Text('Available schemes',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if ((data!['schemes'] as List).isEmpty)
                      const Text('No app scheme is available currently.'),
                    for (final scheme in data!['schemes'])
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(scheme['name'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        '${scheme['duration']} months · Annual rate ${scheme['interest_rate']}%\nMinimum ৳ ${scheme['min_amount']}${scheme['max_amount'] == null ? '' : ' · Maximum ৳ ${scheme['max_amount']}'}\nPremature penalty: ${scheme['penalty_rate'] ?? 0}% of principal'),
                                    const SizedBox(height: 8),
                                    FilledButton(
                                        onPressed: data!['kyc_approved'] != true
                                            ? null
                                            : () async {
                                                await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) => FdrOpenPage(
                                                            api: api,
                                                            scheme: Map<String,
                                                                    dynamic>.from(
                                                                scheme),
                                                            nominees: data![
                                                                'nominees'],
                                                            frequencies: List<
                                                                    String>.from(
                                                                data![
                                                                    'frequencies']))));
                                                load();
                                              },
                                        child:
                                            const Text('Open using savings')),
                                  ]))),
                  ] else
                    TextButton(onPressed: load, child: const Text('Retry')),
                ])));
  }
}

Future<String?> fdrPin(BuildContext context) async {
  String value = '';
  return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: const Text('Confirm with transaction PIN'),
              content: TextField(
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => value = v,
                  decoration: const InputDecoration(labelText: '6-digit PIN')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (value.length == 6) Navigator.pop(ctx, value);
                    },
                    child: const Text('Confirm'))
              ]));
}

class FdrOpenPage extends StatefulWidget {
  final FdrService api;
  final Map<String, dynamic> scheme;
  final List nominees;
  final List<String> frequencies;
  const FdrOpenPage(
      {super.key,
      required this.api,
      required this.scheme,
      required this.nominees,
      required this.frequencies});
  @override
  State<FdrOpenPage> createState() => _FdrOpenPageState();
}

class _FdrOpenPageState extends State<FdrOpenPage> {
  final amount = TextEditingController();
  String key = SendMoneyService.newKey();
  bool busy = false;
  int? nominee;
  Map<String, dynamic>? quote;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void changed() {
    setState(() {
      quote = null;
      error = null;
      key = SendMoneyService.newKey();
    });
  }

  Future<void> preview() async {
    setState(() {
      busy = true;
      error = null;
    });
    final r = await widget.api.request('/quote',
        body: {'scheme_id': widget.scheme['id'], 'amount': amount.text});
    if (!mounted) return;
    setState(() {
      busy = false;
      quote =
          r['success'] == true ? Map<String, dynamic>.from(r['data']) : null;
      error = r['success'] == true ? null : r['message'];
    });
  }

  Future<void> open() async {
    if (busy || quote == null) return;
    setState(() => busy = true);
    final pin = await fdrPin(context);
    if (!mounted) return;
    if (pin == null) {
      setState(() => busy = false);
      return;
    }
    final r = await widget.api.request('/open', body: {
      'scheme_id': widget.scheme['id'],
      'amount': amount.text,
      'frequency': 'At Maturity',
      'auto_renew': false,
      'terms_hash': quote!['terms_hash'],
      'pin': pin,
      'idempotency_key': key,
      'nominees': nominee == null
          ? []
          : [
              {'id': nominee, 'share_percentage': 100}
            ]
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (r['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('FDR is active. Payment deducted from savings.')));
      Navigator.pop(context);
    } else {
      setState(() => error = r['message']);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.scheme['name'])),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(
            'Annual rate: ${widget.scheme['interest_rate']}% · ${widget.scheme['duration']} months'),
        TextField(
            controller: amount,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Principal amount (Tk)'),
            onChanged: (_) => changed()),
        DropdownButtonFormField<String>(
            initialValue: 'At Maturity',
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Interest payout'),
            items: [
              DropdownMenuItem(value: 'At Maturity', child: Text('At Maturity'))
            ],
            onChanged: null),
        if (widget.nominees.isNotEmpty)
          DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Nominee (optional, 100% share)'),
              items: [
                const DropdownMenuItem<int>(
                    value: null, child: Text('No nominee')),
                for (final n in widget.nominees)
                  DropdownMenuItem<int>(value: n['id'], child: Text(n['name']))
              ],
              onChanged: busy
                  ? null
                  : (v) {
                      nominee = v;
                      changed();
                    }),
        const SizedBox(height: 16),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        FilledButton(
            onPressed: busy ? null : preview,
            child: Text(busy ? 'Please wait…' : 'Review FDR')),
        if (quote != null) ...[
          const Divider(),
          Text(
              'Savings deduction: ৳ ${quote!['principal']}\nTerm interest: ৳ ${quote!['term_interest']}\nTotal across the term: ৳ ${quote!['total_term_value']}\nOpening: ${quote!['opening_date']}\nMaturity: ${quote!['maturity_date']}'),
          const Text('Interest is payable at maturity. Auto-renewal is off.'),
          const SizedBox(height: 12),
          Text(quote!['terms']),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: busy ? null : open,
              child: const Text('Pay from savings & activate')),
        ],
      ]));
}

class FdrDetails extends StatefulWidget {
  final FdrService api;
  final int id;
  final bool kyc;
  const FdrDetails(
      {super.key, required this.api, required this.id, required this.kyc});
  @override
  State<FdrDetails> createState() => _FdrDetailsState();
}

class _FdrDetailsState extends State<FdrDetails> {
  Map<String, dynamic>? data;
  String? error;
  String key = SendMoneyService.newKey();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await widget.api.request('/${widget.id}');
    if (!mounted) return;
    setState(() {
      data = r['success'] == true ? Map<String, dynamic>.from(r['data']) : data;
      error = r['success'] == true ? null : r['message'];
    });
  }

  Future<void> encash() async {
    setState(() => busy = true);
    final pin = await fdrPin(context);
    if (!mounted) return;
    if (pin == null) {
      setState(() => busy = false);
      return;
    }
    final r = await widget.api.request('/${widget.id}/encash',
        body: {'pin': pin, 'idempotency_key': key});
    if (!mounted) return;
    setState(() => busy = false);
    if (r['success'] == true) {
      key = SendMoneyService.newKey();
      await load();
    } else {
      setState(() => error = r['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = data?['account'];
    final q = data?['settlement'];
    final pending =
        (data?['requests'] as List? ?? []).any((r) => r['status'] == 'Pending');
    return Scaffold(
        appBar: AppBar(title: const Text('FDR details')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (a == null)
            TextButton(onPressed: load, child: const Text('Load details'))
          else ...[
            Text('${a['fdr_no']} · ${a['status']}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
                'Principal: ৳ ${a['principal_amount']}\nAnnual rate: ${a['interest_rate']}%\nMaturity: ${a['maturity_date']}\nPayout: ${a['interest_payout_frequency']}\nRenewals: ${a['renewal_count']}'),
            if (q != null) ...[
              const Divider(),
              const Text('Encashment preview',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'As of business date: ${q['date']}\nEarned interest: ৳ ${q['earned_interest']}\nAlready paid: ৳ ${q['paid_interest']}\nPenalty: ৳ ${q['penalty_amount']}\nReturn to savings: ৳ ${q['net_payable']}'),
              const Text(
                  'Funds return only after admin approval. Final settlement is recalculated on approval.'),
              if (pending)
                const Text('Encashment: Pending admin approval',
                    style: TextStyle(color: Colors.orange))
              else
                FilledButton(
                    onPressed: busy || !widget.kyc ? null : encash,
                    child: Text(busy
                        ? 'Please wait…'
                        : 'Request encashment to savings')),
            ],
            const SizedBox(height: 20),
            const Text('Request history',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final r in data!['requests'])
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${r['status']} · ${r['requested_date']}'),
                  subtitle: Text(r['review_note'] ?? '')),
            const Text('Transaction history',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final t in a['transactions'])
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${t['type']} · ৳ ${t['amount']}'),
                  subtitle: Text('${t['date']}\n${t['note'] ?? ''}')),
          ],
        ]));
  }
}
