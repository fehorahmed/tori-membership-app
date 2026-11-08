import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state.dart';
import 'ui.dart';

class PaymentSecurityPanel extends StatefulWidget {
  final ToriState state;
  final VoidCallback onAuthorized;
  const PaymentSecurityPanel(
      {super.key, required this.state, required this.onAuthorized});
  @override
  State<PaymentSecurityPanel> createState() => _PaymentSecurityPanelState();
}

class _PaymentSecurityPanelState extends State<PaymentSecurityPanel> {
  int phase = 1, countdown = 45;
  bool verified = false;
  String pin = '';
  final otp = TextEditingController();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 0 && mounted) setState(() => countdown--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    otp.dispose();
    super.dispose();
  }

  void verify() async {
    if (otp.text.length < 4 || verified) return;
    FocusScope.of(context).unfocus();
    setState(() => verified = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => phase = 2);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state, p = Palette(s.dark);
    return panel(
        p,
        phase == 1
            ? stack([
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: p.border,
                            borderRadius: BorderRadius.circular(2)))),
                Center(
                    child: text(
                        verified
                            ? s.tr('OTP Verified Successfully!',
                                'ওটিপি সফলভাবে যাচাই হয়েছে!')
                            : s.tr('Step 1: OTP Verification',
                                '১ম ধাপ: ওটিপি যাচাইকরণ'),
                        size: 19,
                        color: verified ? p.primary : p.ink,
                        align: TextAlign.center)),
                if (verified)
                  Center(
                      child:
                          Icon(Icons.check_circle, color: p.primary, size: 72))
                else ...[
                  Center(child: pill('+880 1719 •••• 401', p.muted, size: 12)),
                  SizedBox(
                      height: 58,
                      child: Stack(children: [
                        Row(children: [
                          for (int i = 0; i < 4; i++)
                            Expanded(
                                child: Container(
                                    margin:
                                        EdgeInsets.only(right: i < 3 ? 10 : 0),
                                    decoration: BoxDecoration(
                                        color: p.ground,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: i == otp.text.length
                                                ? p.primary
                                                : p.border,
                                            width: 1.5)),
                                    child: Center(
                                        child: text(
                                            i < otp.text.length
                                                ? otp.text[i]
                                                : '·',
                                            size: 24,
                                            color: p.ink))))
                        ]),
                        Positioned.fill(
                            child: Opacity(
                                opacity: .01,
                                child: TextField(
                                    controller: otp,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4)
                                    ],
                                    onChanged: (v) {
                                      setState(() {});
                                      if (v.length == 4) verify();
                                    },
                                    decoration: const InputDecoration(
                                        border: InputBorder.none))))
                      ])),
                  Center(
                      child: text(
                          s.tr('Resend code in ${countdown}s',
                              'আবার কোড পাঠান ${countdown}s'),
                          size: 12,
                          color: p.muted)),
                  primary(s.tr('Verify Code', 'কোড যাচাই করুন'),
                      otp.text.length == 4 ? verify : null,
                      gradient: true, icon: Icons.chevron_right),
                  Center(
                      child: link(s.tr('Resend via SMS', 'এসএমএস পাঠান'), () {
                    if (countdown == 0)
                      setState(() {
                        otp.clear();
                        countdown = 45;
                      });
                  }))
                ]
              ], spacing: 16)
            : stack([
                Center(
                    child: CircleAvatar(
                        radius: 27,
                        backgroundColor:
                            const Color(0xFF06B6D4).withValues(alpha: .15),
                        child: const Icon(Icons.lock,
                            color: Color(0xFF06B6D4), size: 28))),
                Center(
                    child: text(
                        s.tr('Step 2: Transaction PIN',
                            '২য় ধাপ: ট্রানজেকশন পিন'),
                        size: 18,
                        color: p.ink)),
                Center(
                    child: text(
                        s.tr(
                            'Enter your 6-digit transaction PIN to authorize ${s.money(s.amount, decimals: false)}',
                            '${s.money(s.amount, decimals: false)} স্থানান্তরের অনুমোদন দিতে আপনার সিকিউরিটি পিন দিন'),
                        size: 12,
                        color: p.muted,
                        align: TextAlign.center)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 0; i < 6; i++)
                    Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < pin.length ? p.primary : p.border))
                ]),
                for (final keys in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['BIO', '0', 'DEL']
                ])
                  Row(children: [
                    for (final key in keys)
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: InkWell(
                                  onTap: () => setState(() {
                                        if (key == 'BIO')
                                          pin = '982341';
                                        else if (key == 'DEL') {
                                          if (pin.isNotEmpty)
                                            pin = pin.substring(
                                                0, pin.length - 1);
                                        } else if (pin.length < 6) pin += key;
                                      }),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                          color: key.length == 1
                                              ? p.raised
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: key.length == 1
                                                  ? p.border
                                                  : Colors.transparent)),
                                      child: Center(
                                          child: key == 'BIO'
                                              ? Icon(Icons.fingerprint,
                                                  size: 24, color: p.primary)
                                              : key == 'DEL'
                                                  ? Icon(
                                                      Icons.backspace_outlined,
                                                      size: 22,
                                                      color: p.muted)
                                                  : text(key,
                                                      size: 18,
                                                      color: p.ink))))))
                  ]),
                primary(
                    s.tr('Confirm & Authorize Transfer',
                        'স্থানান্তর নিশ্চিত করুন'),
                    pin.length == 6 ? widget.onAuthorized : null)
              ], spacing: 16),
        padding: 20,
        radius: phase == 1 ? 28 : 20);
  }
}
