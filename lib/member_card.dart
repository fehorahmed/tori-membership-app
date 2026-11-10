import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dialogs.dart';
import 'services/profile_service.dart';
import 'state.dart';
import 'ui.dart';
import 'virtual_debit_card_widget.dart';

class MemberCardPage extends StatefulWidget {
  final ToriState state;
  final ProfileService? service;
  const MemberCardPage({super.key, required this.state, this.service});
  @override
  State<MemberCardPage> createState() => _MemberCardPageState();
}

class _MemberCardPageState extends State<MemberCardPage> {
  late final service = widget.service ?? ProfileService();
  bool loading = true, visible = false;
  String? error;
  Map<String, dynamic>? card;
  ToriState get s => widget.state;

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
    setState(() {
      loading = true;
      error = null;
      visible = false;
      card = null;
    });
    final result = await service.fetchCard(language: s.bengali ? 'bn' : 'en');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (result['success'] == true) {
        card = result['data']['card'];
      } else {
        error = result['message'];
      }
    });
  }

  String status(String value) => switch (value) {
        'Active' => s.tr('Active', 'সক্রিয়'),
        'Suspended' => s.tr('Suspended', 'স্থগিত'),
        'Lost' => s.tr('Lost', 'হারিয়ে গেছে'),
        'Damaged' => s.tr('Damaged', 'ক্ষতিগ্রস্ত'),
        'Expired' => s.tr('Expired', 'মেয়াদোত্তীর্ণ'),
        'Revoked' => s.tr('Revoked', 'বাতিল'),
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    final p = Palette(s.dark);
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return pageBody([
        text(error!, color: p.error),
        primary(s.tr('Retry', 'আবার চেষ্টা করুন'), load),
      ]);
    if (card == null)
      return pageBody([
        Icon(Icons.credit_card_off_outlined, size: 64, color: p.muted),
        text(s.tr('No card issued yet', 'এখনো কার্ড ইস্যু হয়নি'),
            size: 22, color: p.ink),
        text(
            s.tr(
                'Your membership card will appear here after it is issued by your branch.',
                'আপনার শাখা থেকে মেম্বারশিপ কার্ড ইস্যু করা হলে এখানে দেখা যাবে।'),
            color: p.muted),
        secondary(s.tr('Refresh', 'রিফ্রেশ করুন'), load, p),
      ]);
    final details = card!;
    final number = details['card_number'] as String;
    final masked = number.length > 4
        ? '•••• •••• ${number.substring(number.length - 4)}'
        : '••••';
    final active = details['status'] == 'Active';
    return pageBody([
      pill(status(details['status']), active ? p.primary : p.error),
      Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                  aspectRatio: 1.586,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                          width: 420,
                          child: VirtualDebitCardWidget(
                              cardholderName: details['holder_name'] ?? '',
                              cardNumber: visible ? number : masked,
                              issuedAt: details['issued_at'] ?? '—',
                              mfiId: details['member_no'] ?? '—',
                              isBengali: s.bengali,
                              isFrozen: !active)))))),
      secondary(
          visible
              ? s.tr('Hide card number', 'কার্ড নম্বর লুকান')
              : s.tr('Show card number', 'কার্ড নম্বর দেখুন'),
          () => setState(() => visible = !visible),
          p,
          icon: visible ? Icons.visibility_off : Icons.visibility),
      panel(
          p,
          stack([
            infoRow(s.tr('Cardholder', 'কার্ডধারী'),
                details['holder_name'] ?? '—', p),
            infoRow(s.tr('Member ID', 'সদস্য নম্বর'),
                details['member_no'] ?? '—', p),
            infoRow(s.tr('Card number', 'কার্ড নম্বর'),
                visible ? number : masked, p),
            if (visible)
              secondary(s.tr('Copy card number', 'কার্ড নম্বর কপি করুন'), () {
                Clipboard.setData(ClipboardData(text: number));
                toast(context,
                    s.tr('Card number copied', 'কার্ড নম্বর কপি হয়েছে'));
              }, p),
            infoRow(s.tr('Issuing branch', 'ইস্যুকারী শাখা'),
                details['branch'] ?? '—', p),
            infoRow(s.tr('Issued on', 'ইস্যুর তারিখ'),
                details['issued_at'] ?? '—', p),
            infoRow(s.tr('Card issue fee', 'কার্ড ইস্যু ফি'),
                s.money((details['fee'] as num?) ?? 0), p),
            infoRow(
                s.tr('Fee payment', 'ফি পরিশোধ'),
                details['fee_status'] == 'Received'
                    ? s.tr('Paid', 'পরিশোধিত')
                    : s.tr('Pending', 'বাকি'),
                p),
            infoRow(
                s.tr('Last printed', 'সর্বশেষ প্রিন্ট'),
                details['printed_at'] ??
                    s.tr('Not printed yet', 'এখনো প্রিন্ট হয়নি'),
                p),
          ])),
      if (!active)
        text(
            s.tr('Contact your branch about your card status.',
                'কার্ডের অবস্থা সম্পর্কে আপনার শাখায় যোগাযোগ করুন।'),
            color: p.error),
      secondary(s.tr('Refresh', 'রিফ্রেশ করুন'), load, p),
    ]);
  }
}
