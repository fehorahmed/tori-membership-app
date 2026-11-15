import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state.dart';
import 'dialogs.dart';
import 'services/referral_service.dart';

Future<void> showReferrals(BuildContext context, ToriState state) async {
  await openPage<void>(
      context,
      state,
      state.tr('Referral Points', 'রেফারেল পয়েন্ট'),
      (_) => ReferralPointsPage(state: state));
  await state.loadDashboardData();
}

class ReferralPointsPage extends StatefulWidget {
  final ToriState state;
  final ReferralService? service;
  const ReferralPointsPage({super.key, required this.state, this.service});
  @override
  State<ReferralPointsPage> createState() => _ReferralPointsPageState();
}

class _ReferralPointsPageState extends State<ReferralPointsPage> {
  late final service = widget.service ?? ReferralService();
  final points = TextEditingController(), pin = TextEditingController();
  Map<String, dynamic>? data, pending;
  String? message;
  bool loading = true, busy = false;
  ToriState get s => widget.state;
  String get lang => s.bengali ? 'bn' : 'en';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    points.dispose();
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
      if (saved != null &&
          (next['redemptions'] as List)
              .any((r) => r['request_key'] == saved!['request_key'])) {
        await service.clear(next['customer_id']);
        saved = null;
      }
      if (!mounted) return;
      setState(() {
        data = next;
        pending = saved;
        loading = false;
      });
    } else {
      setState(() {
        message = result['message'];
        loading = false;
      });
    }
  }

  Future<void> redeem() async {
    if (busy || data == null) return;
    final count = pending?['points'] ?? int.tryParse(points.text);
    final rate = '${pending?['point_value'] ?? data!['point_value']}';
    if (count == null ||
        count < 1 ||
        (pending == null && count > data!['points'])) {
      setState(() => message = s.tr(
          'Enter valid available points.', 'সঠিক ব্যবহারযোগ্য পয়েন্ট লিখুন।'));
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin.text)) {
      setState(() =>
          message = s.tr('Enter your 6-digit PIN.', '৬ সংখ্যার পিন লিখুন।'));
      return;
    }
    final total = (count * double.parse(rate)).toStringAsFixed(2);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(s.tr('Confirm redemption', 'রিডিম নিশ্চিত করুন')),
                content: Text(s.tr(
                    'Redeem $count points for Tk $total into your savings account?',
                    '$count পয়েন্ট রিডিম করে সঞ্চয় হিসাবে ৳$total জমা করবেন?')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.tr('Cancel', 'বাতিল'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.tr('Confirm', 'নিশ্চিত করুন')))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      message = null;
    });
    final result =
        await service.redeem(data!['customer_id'], count, rate, pin.text, lang);
    pin.clear();
    if (!mounted) return;
    setState(() {
      message = result['success'] == true
          ? s.tr('Tk ${result['data']['amount']} credited to savings.',
              'সঞ্চয় হিসাবে ৳${result['data']['amount']} জমা হয়েছে।')
          : result['message'];
    });
    if (result['success'] == true) points.clear();
    await load();
    if (mounted) setState(() => busy = false);
  }

  Future<void> collectMilestones() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    final result =
        await service.send('referrals/milestones/collect', lang, body: {});
    if (!mounted) return;
    setState(() {
      message = result['success'] == true
          ? s.tr('Milestone bonuses checked. See payment status below.',
              'মাইলস্টোন বোনাস যাচাই হয়েছে। নিচে পেমেন্টের অবস্থা দেখুন।')
          : result['message'];
    });
    await load();
    if (mounted) setState(() => busy = false);
  }

  Widget milestoneSection() {
    final config = Map<String, dynamic>.from(data!['milestones']);
    final bonuses = List<Map<String, dynamic>>.from(
        (config['bonuses'] as List).map((b) => Map<String, dynamic>.from(b)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      Text(s.tr('Milestone cash bonus', 'মাইলস্টোন ক্যাশ বোনাস'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(s.tr(
          'Progress uses remaining referral points. Redeeming lowers progress. Each milestone pays once into savings without spending points.',
          'অবশিষ্ট রেফারেল পয়েন্ট দিয়ে অগ্রগতি গণনা হয়। রিডিম করলে অগ্রগতি কমবে। প্রতিটি মাইলস্টোন একবার সঞ্চয়ে টাকা জমা করবে; পয়েন্ট কাটবে না।')),
      for (final tier in config['tiers'] as List)
        if (tier['enabled'] == true)
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${tier['threshold']} ${s.tr('points', 'পয়েন্ট')} · ${tier['percentage']}%'),
              subtitle: Text(
                  '${s.tr('Progress', 'অগ্রগতি')}: ${(data!['points'] as int).clamp(0, tier['threshold'] as int)}/${tier['threshold']}')),
      for (final bonus in bonuses)
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
                '${bonus['threshold']} ${s.tr('point milestone', 'পয়েন্ট মাইলস্টোন')} · Tk ${bonus['amount']}'),
            subtitle: Text(bonus['paid_at'] != null
                ? s.tr('Paid to savings: ${bonus['paid_at']}',
                    'সঞ্চয়ে জমা: ${bonus['paid_at']}')
                : s.tr(
                    'Earned; awaiting an active savings account and posting setup.',
                    'অর্জিত; সক্রিয় সঞ্চয় হিসাব ও পোস্টিং সেটআপের অপেক্ষায়।'))),
      OutlinedButton(
          onPressed:
              busy || config['enabled'] != true || data!['enabled'] != true
                  ? null
                  : collectMilestones,
          child: Text(s.tr('Check / collect milestone bonus',
              'মাইলস্টোন বোনাস যাচাই / সংগ্রহ করুন'))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
        onRefresh: () async {
          if (!busy) await load();
        },
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (message != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(message!, key: const Key('referral-message'))),
              if (data != null) ...[
                Text(
                    '${s.tr('Available points', 'ব্যবহারযোগ্য পয়েন্ট')}: ${data!['points']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22)),
                Text(
                    '${s.tr('1 point', '১ পয়েন্ট')} = Tk ${data!['point_value']}'),
                Text(
                    '${s.tr('Redeemable value', 'রিডিম মূল্য')}: Tk ${data!['redeemable_amount']}'),
                Text(
                    '${s.tr('Referrals / Rewarded', 'রেফারেল / বোনাসপ্রাপ্ত')}: ${data!['referral_count']} / ${data!['rewarded_count']}'),
                const SizedBox(height: 16),
                Text(s.tr(
                    'Points are earned after your referred member pays the full registration fee. Redeem manually at the current point value.',
                    'আপনার রেফার করা মেম্বারের সম্পূর্ণ নিবন্ধন ফি কাটা হলে পয়েন্ট পাবেন। বর্তমান পয়েন্টের মূল্যে নিজে রিডিম করতে পারবেন।')),
                if (data!['enabled'] != true)
                  Text(s.tr('Redemption is currently unavailable.',
                      'রিডিম বর্তমানে বন্ধ আছে।')),
                if (pending != null)
                  Text(s.tr(
                      'An earlier redemption is awaiting confirmation. Retry the same request with your PIN.',
                      'আগের রিডিমের ফলাফল নিশ্চিত হয়নি। পিন দিয়ে একই অনুরোধ আবার চেষ্টা করুন।')),
                const SizedBox(height: 16),
                TextField(
                    controller: points,
                    enabled: !busy && pending == null,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 7,
                    decoration: InputDecoration(
                        labelText: s.tr('Points to redeem', 'রিডিমের পয়েন্ট'))),
                TextField(
                    controller: pin,
                    enabled: !busy,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    decoration: InputDecoration(
                        labelText: s.tr('Transaction PIN', 'লেনদেনের পিন'))),
                FilledButton(
                    onPressed:
                        busy || (data!['enabled'] != true && pending == null)
                            ? null
                            : redeem,
                    child: Text(busy
                        ? s.tr('Processing…', 'প্রক্রিয়াধীন…')
                        : pending != null
                            ? s.tr('Retry redemption', 'আবার চেষ্টা করুন')
                            : s.tr('Redeem to savings',
                                'সঞ্চয় হিসাবে রিডিম করুন'))),
                const SizedBox(height: 24),
                if (data!['milestones'] is Map) milestoneSection(),
                Text(s.tr('Redemption history', 'রিডিমের ইতিহাস'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                for (final row in data!['redemptions'] as List)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          '${row['points']} ${s.tr('points', 'পয়েন্ট')} · Tk ${row['amount']}'),
                      subtitle: Text('${row['created_at']}')),
              ] else
                TextButton(
                    onPressed: busy ? null : load,
                    child: Text(s.tr('Retry', 'আবার চেষ্টা করুন'))),
            ]));
  }
}
