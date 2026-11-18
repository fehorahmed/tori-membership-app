import 'package:flutter/material.dart';
import 'state.dart';
import 'send_money.dart';
import 'services/beneficiary_service.dart';

class QuickSendPanel extends StatefulWidget {
  final ToriState state;
  final BeneficiaryService? service;
  final bool expanded;
  const QuickSendPanel(
      {super.key, required this.state, this.service, this.expanded = false});
  @override
  State<QuickSendPanel> createState() => _QuickSendPanelState();
}

class _QuickSendPanelState extends State<QuickSendPanel> {
  late final service = widget.service ?? BeneficiaryService();
  List<Map<String, dynamic>> items = [];
  bool loading = true, busy = false;
  String? error;
  ToriState get s => widget.state;
  String get lang => s.bengali ? 'bn' : 'en';
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.service == null) service.close();
    super.dispose();
  }

  Future<void> load() async {
    final result = await service.list(lang);
    if (!mounted) return;
    setState(() {
      loading = false;
      error = result['success'] == true ? null : result['message'];
      if (result['success'] == true)
        items = (result['data']['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    });
  }

  void message(String value) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  }

  Future<String?> input(String title, {String value = '', int limit = 60}) =>
      showDialog<String>(
          context: context,
          builder: (_) => _RecipientInput(
              title: title,
              value: value,
              limit: limit,
              cancel: s.tr('Cancel', 'বাতিল'),
              proceed: s.tr('Continue', 'পরবর্তী')));

  Future<void> add() async {
    if (busy) return;
    final code = await input(
        s.tr('Mobile number or Member ID', 'মোবাইল নম্বর অথবা মেম্বার আইডি'),
        limit: 64);
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => busy = true);
    final result = await service.lookup(code, lang);
    if (!mounted) return;
    setState(() => busy = false);
    if (result['success'] != true) {
      message(result['message'] ?? 'Unable to find member');
      return;
    }
    final member = result['data'];
    final nickname = await input(
        '${member['name']}\n${member['member_no'] ?? ''}\n${s.tr('Nickname (optional)', 'ডাকনাম (ঐচ্ছিক)')}');
    if (nickname == null || !mounted) return;
    setState(() => busy = true);
    final saved = await service.save(member['recipient_id'], nickname, lang);
    if (!mounted) return;
    setState(() => busy = false);
    if (saved['success'] != true) message(saved['message'] ?? 'Unable to save');
    await load();
  }

  Future<void> manage(Map<String, dynamic> row) async {
    final action = await showDialog<String>(
        context: context,
        builder: (ctx) =>
            SimpleDialog(title: Text(row['name'] ?? ''), children: [
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, 'edit'),
                  child: Text(s.tr('Edit nickname', 'ডাকনাম পরিবর্তন'))),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, 'remove'),
                  child: Text(s.tr('Remove', 'সরিয়ে দিন')))
            ]));
    if (!mounted || action == null) return;
    String? nickname;
    if (action == 'edit') {
      nickname =
          await input(s.tr('Nickname', 'ডাকনাম'), value: row['nickname'] ?? '');
      if (nickname == null) return;
    } else {
      final approved = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(s.tr(
                      'Remove from Quick Send?', 'Quick Send থেকে সরাবেন?')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(s.tr('Cancel', 'বাতিল'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(s.tr('Remove', 'সরিয়ে দিন')))
                  ]));
      if (approved != true) return;
    }
    if (!mounted) return;
    final result = await service.change(row['id'], lang, nickname: nickname);
    if (result['success'] != true)
      message(result['message'] ?? 'Unable to update');
    await load();
  }

  Widget avatar(Map<String, dynamic> row) {
    final name = (row['name'] ?? '?').toString().trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase();
    return CircleAvatar(
        radius: 24,
        child: row['image'] == null
            ? Text(initials)
            : ClipOval(
                child: Image.network(row['image'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(initials))));
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.expanded ? items : items.take(5);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(s.tr('Quick Send', 'দ্রুত পাঠান'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600))),
        if (!widget.expanded)
          TextButton(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                            appBar: AppBar(
                                title: Text(s.tr('Quick Send', 'দ্রুত পাঠান'))),
                            body: Padding(
                                padding: const EdgeInsets.all(16),
                                child: QuickSendPanel(
                                    state: s, expanded: true)))));
                await load();
              },
              child: Text(s.tr('View all', 'সব দেখুন')))
      ]),
      if (loading || busy) const LinearProgressIndicator(),
      if (error != null)
        TextButton(
            onPressed: load,
            child: Text(
                s.tr('Unable to load. Retry', 'লোড হয়নি। আবার চেষ্টা করুন'))),
      SizedBox(
          height: 110,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            SizedBox(
                width: 76,
                child: InkWell(
                    onTap: busy ? null : add,
                    child: Column(children: [
                      const CircleAvatar(radius: 24, child: Icon(Icons.add)),
                      const SizedBox(height: 8),
                      Text(s.tr('Add New', 'নতুন'), textAlign: TextAlign.center)
                    ]))),
            for (final row in visible)
              SizedBox(
                  width: 82,
                  child: InkWell(
                      onLongPress: busy ? null : () => manage(row),
                      onTap: row['active'] != true
                          ? null
                          : () async {
                              await showSendMoney(context, s,
                                  initialRecipient:
                                      row['member_no'] ?? row['name'],
                                  recipientId: row['recipient_id']);
                              await load();
                            },
                      child: Opacity(
                          opacity: row['active'] == true ? 1 : .4,
                          child: Column(children: [
                            avatar(row),
                            const SizedBox(height: 8),
                            Text(
                                (row['nickname'] ?? row['name'] ?? '')
                                    .toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center)
                          ]))))
          ])),
      if (widget.expanded)
        Text(s.tr('Hold a recipient to edit or remove. Up to 10 recipients.',
            'পরিবর্তন বা সরাতে প্রাপককে চেপে ধরুন। সর্বোচ্চ ১০ জন।')),
    ]);
  }
}

class _RecipientInput extends StatefulWidget {
  final String title, value, cancel, proceed;
  final int limit;
  const _RecipientInput(
      {required this.title,
      required this.value,
      required this.limit,
      required this.cancel,
      required this.proceed});
  @override
  State<_RecipientInput> createState() => _RecipientInputState();
}

class _RecipientInputState extends State<_RecipientInput> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: TextField(
              controller: controller, maxLength: widget.limit, autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(widget.proceed))
          ]);
}
