import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'state.dart';
import 'ui.dart';

enum AuthStep { mobile, registration, forgot, otp, pin }

class WelcomeScreen extends StatefulWidget {
  final ToriState state;
  const WelcomeScreen({super.key, required this.state});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  AuthStep step = AuthStep.mobile;
  final mobile = TextEditingController(text: '1755 892 401'),
      pin = TextEditingController(),
      confirmPin = TextEditingController(),
      otp = TextEditingController();
  final name = TextEditingController(),
      signupMobile = TextEditingController(),
      email = TextEditingController(),
      signupPin = TextEditingController();
  final otpFocus = FocusNode();
  bool consent = true, visible = false, busy = false, success = false;
  String? error;
  String? verificationToken;
  bool hasPin = true;
  int countdown = 60;
  Timer? timer;
  ToriState get s => widget.state;
  Palette get p => Palette(s.dark);
  String tr(String a, String b) => s.tr(a, b);
  @override
  void dispose() {
    timer?.cancel();
    for (final c in [mobile, pin, confirmPin, otp, name, signupMobile, email, signupPin]) {
      c.dispose();
    }
    otpFocus.dispose();
    super.dispose();
  }

  void go(AuthStep value) {
    FocusScope.of(context).unfocus();
    setState(() {
      step = value;
      error = null;
      success = false;
    });
    if (value == AuthStep.otp) {
      otp.clear();
      resetTimer();
    }
  }

  void resetTimer() {
    timer?.cancel();
    setState(() => countdown = 60);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || step != AuthStep.otp) {
        t.cancel();
        return;
      }
      if (countdown > 0)
        setState(() => countdown--);
      else
        t.cancel();
    });
  }

  Future<void> continueMobile() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });

    final res = await AuthService.initiateLogin(mobile.text, language: s.bengali ? 'bn' : 'en');
    if (!mounted) return;
    setState(() => busy = false);

    if (res['success'] == true) {
      final data = res['data'];
      hasPin = data['has_pin'] ?? true;
      // If server returns debug_otp in local dev, prefill it for convenience
      if (data['debug_otp'] != null) {
        otp.text = data['debug_otp'].toString();
      }
      go(AuthStep.otp);
    } else {
      setState(() => error = res['message']);
    }
  }

  Future<void> verifyOtp() async {
    if (busy || success) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });

    final res = await AuthService.verifyOtp(
      rawMobile: mobile.text,
      otp: otp.text,
      language: s.bengali ? 'bn' : 'en',
    );

    if (!mounted) return;
    if (res['success'] == true) {
      verificationToken = res['data']['verification_token'];
      hasPin = res['data']['has_pin'] ?? true;
      HapticFeedback.mediumImpact();
      setState(() {
        busy = false;
        success = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) go(AuthStep.pin);
    } else {
      setState(() {
        busy = false;
        error = res['message'];
      });
    }
  }

  Future<void> submitPin() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });

    // If verification token exists, authenticate with real backend API
    if (verificationToken != null) {
      if (!hasPin && pin.text != confirmPin.text) {
        setState(() {
          busy = false;
          error = tr('PINs do not match. Please re-enter.', 'দুইটি পিন মেলেনি। পুনরায় দিন।');
        });
        return;
      }

      final res = hasPin
          ? await AuthService.loginWithPin(
              rawMobile: mobile.text,
              pin: pin.text,
              verificationToken: verificationToken!,
              language: s.bengali ? 'bn' : 'en',
            )
          : await AuthService.setPin(
              verificationToken: verificationToken!,
              language: s.bengali ? 'bn' : 'en',
              pin: pin.text,
              pinConfirmation: confirmPin.text,
            );

      if (!mounted) return;
      setState(() => busy = false);

      if (res['success'] == true) {
        s.login();
      } else {
        setState(() => error = res['message']);
      }
    } else {
      // Fallback local verification
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => busy = false);
      if (s.verifyPin(pin.text)) {
        s.login();
      } else {
        setState(() => error = tr('Invalid Security PIN.', 'ভুল সিকিউরিটি পিন।'));
      }
    }
  }

  Widget card(Widget child) => panel(p, child,
      radius: 22,
      padding: 20,
      color: s.dark ? const Color(0xFF131C31) : Colors.white,
      shadow: true);
  Widget errorText() => error == null
      ? const SizedBox.shrink()
      : text(error!, size: 12, color: p.error);
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: AuthBackground(s.dark))),
        SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(children: [
                                    // Top Bar with Logo & Language Toggle
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Center(child: Emblem())),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          onTap: () {
                                            s.setLanguage(!s.bengali);
                                            setState(() => error = null);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: s.dark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: p.border
                                                      .withValues(alpha: 0.6)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.language,
                                                    size: 14, color: p.muted),
                                                hgap(6),
                                                text(s.bengali ? 'English' : 'বাংলা',
                                                    size: 12,
                                                    weight: FontWeight.w600,
                                                    color: p.ink),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    gap(28),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          text(
                                              tr('Welcome to TORI',
                                                  'তোরী-তে স্বাগতম'),
                                              size: 28,
                                              weight: FontWeight.w800,
                                              color: p.ink,
                                              family: 'PlusJakartaSans',
                                              spacing: -.7),
                                          gap(6),
                                          text(
                                              tr('Enter your mobile number to continue',
                                                  'এগিয়ে যেতে আপনার মোবাইল নম্বর দিন'),
                                              size: 14,
                                              color: p.muted,
                                              weight: FontWeight.w400),
                                        ],
                                      ),
                                    ),
                                    gap(24),
                                    AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: KeyedSubtree(
                                            key: ValueKey(step),
                                            child: switch (step) {
                                              AuthStep.mobile => mobileCard(),
                                              AuthStep.registration =>
                                                registrationCard(),
                                              AuthStep.forgot => forgotCard(),
                                              AuthStep.otp => otpCard(),
                                              AuthStep.pin => pinCard()
                                            })),
                                  ]),
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          top: 24, bottom: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shield_outlined,
                                              size: 13,
                                              color: p.muted
                                                  .withValues(alpha: 0.7)),
                                          hgap(6),
                                          text(
                                              tr('End-to-end encrypted & secure',
                                                  'সম্পূর্ণ নিরাপদ ও সুরক্ষিত এনক্রিপশন'),
                                              size: 11,
                                              color: p.muted
                                                  .withValues(alpha: 0.8),
                                              weight: FontWeight.w500),
                                        ],
                                      )),
                                ])))))),
      ]));
  Widget mobileCard() => Column(children: [
        card(stack([
          text(tr('Phone Number', 'মোবাইল নম্বর'),
              size: 13, weight: FontWeight.w600, color: p.ink),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: s.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: error != null
                          ? p.error
                          : p.border.withValues(alpha: 0.8),
                      width: 1.2)),
              child: Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: s.dark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border.withValues(alpha: 0.5))),
                    child: Row(children: [
                      Container(
                          width: 18,
                          height: 12,
                          decoration: BoxDecoration(
                              color: const Color(0xFF006A4E),
                              borderRadius: BorderRadius.circular(2)),
                          child: Align(
                              alignment: const Alignment(-.16, 0),
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFF42A41),
                                      shape: BoxShape.circle)))),
                      hgap(6),
                      text('+880', size: 14.5, weight: FontWeight.w600, color: p.ink),
                    ])),
                hgap(12),
                Expanded(
                    child: TextField(
                        key: const Key('mobile-input'),
                        controller: mobile,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => continueMobile(),
                        style: font(17.5,
                            weight: FontWeight.w600,
                            color: p.ink,
                            spacing: 1.2),
                        decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '1XXX XXXXXX',
                            hintStyle: font(16, color: p.muted.withValues(alpha: 0.5)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12)))),
                if (mobile.text.length >= 10)
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: Color(0xFF0D9488))
              ])),
          if (error != null) errorText(),
          gap(4),
          primary(tr('Continue', 'এগিয়ে যান'), continueMobile,
              gradient: true, busy: busy, icon: Icons.arrow_forward_rounded),
          gap(4),
          Center(
            child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  toast(
                      context,
                      tr('Biometric authenticated for +880 ${mobile.text}',
                          'বায়োমেট্রিক অথেন্টিকেশন সফল হয়েছে'));
                  go(AuthStep.otp);
                },
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint_rounded,
                              size: 20, color: Color(0xFF0D9488)),
                          hgap(8),
                          text(
                              tr('Use Biometric Login',
                                  'বায়োমেট্রিক দিয়ে লগইন করুন'),
                              size: 13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF0D9488))
                        ]))),
          )
        ])),
        gap(20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          text(tr("Don't have an account? ", 'অ্যাকাউন্ট নেই? '),
              size: 13.5, color: p.muted),
          link(tr('Register Now', 'নিবন্ধন করুন'),
              () => go(AuthStep.registration),
              size: 13.5)
        ]),
        gap(10),
        link(
            tr('Need Help? Contact Support', 'সাহায্য প্রয়োজন? যোগাযোগ করুন'),
            () => toast(context,
                tr('TORI 24/7 Helpline: 16789', 'তোরী হেল্পলাইন: ১৬৭৮৯')),
            size: 12)
      ]);
  Widget pinCard() => card(stack([
        Row(children: [
          text(
              hasPin
                  ? tr('SECURITY PIN', 'সিকিউরিটি পিন')
                  : tr('SET 6-DIGIT PIN', 'নতুন ৬-ডিজিটের পিন দিন'),
              size: 12,
              color: p.ink,
              spacing: .8),
          hgap(6),
          const Icon(Icons.circle, size: 6, color: Color(0xFF0D9488)),
          const Spacer(),
          if (hasPin)
            link(tr('Forgot PIN?', 'পিন ভুলে গেছেন?'), () => go(AuthStep.forgot))
        ]),
        if (!hasPin)
          text(
              tr('Create a new 6-digit PIN for your account.',
                  'আপনার অ্যাকাউন্টের জন্য নতুন ৬ ডিজিটের পিন তৈরি করুন।'),
              size: 11.5,
              color: p.muted),
        // PIN Input
        Container(
            height: 56,
            decoration: BoxDecoration(
                color: p.ground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: error == null ? const Color(0xFF0D9488) : p.error,
                    width: 2)),
            child: Row(children: [
              hgap(20),
              Expanded(
                  child: TextField(
                      key: const Key('pin-input'),
                      controller: pin,
                      obscureText: !visible,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => submitPin(),
                      style: font(22,
                          color: p.ink, family: 'monospace', spacing: 10),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hasPin ? '••••••' : tr('Enter 6-digit PIN', '৬ ডিজিটের পিন দিন'),
                          hintStyle: font(15, color: p.muted.withValues(alpha: .5), spacing: 0),
                          contentPadding: EdgeInsets.zero))),
              IconButton(
                  onPressed: () => setState(() => visible = !visible),
                  icon: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: p.muted))
            ])),
        // Confirm PIN Input (Only if First Time Setup: !hasPin)
        if (!hasPin) ...[
          text(tr('CONFIRM PIN', 'পিন নিশ্চিত করুন'),
              size: 12, color: p.ink, spacing: .8),
          Container(
              height: 56,
              decoration: BoxDecoration(
                  color: p.ground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: error == null ? const Color(0xFF0D9488) : p.error,
                      width: 1.5)),
              child: Row(children: [
                hgap(20),
                Expanded(
                    child: TextField(
                        key: const Key('confirm-pin-input'),
                        controller: confirmPin,
                        obscureText: !visible,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6)
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => submitPin(),
                        style: font(22,
                            color: p.ink, family: 'monospace', spacing: 10),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: hasPin ? '••••••' : tr('Re-enter 6-digit PIN', 'পুনরায় ৬ ডিজিটের পিন দিন'),
                            hintStyle: font(15, color: p.muted.withValues(alpha: .5), spacing: 0),
                            contentPadding: EdgeInsets.zero))),
                IconButton(
                    onPressed: () => setState(() => visible = !visible),
                    icon: Icon(
                        visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: p.muted))
              ])),
        ],
        Row(children: [
          Expanded(
              child: text(
                  tr('Standard 6-digit corporate PIN',
                      'স্ট্যান্ডার্ড ৬-ডিজিটের কর্পোরেট পিন'),
                  size: 11,
                  color: p.muted)),
          text(tr('● Session Encrypted', '● সেশন এনক্রিপ্টেড'),
              size: 10.5, color: p.primary)
        ]),
        if (error != null) errorText(),
        primary(
            hasPin ? tr('Login', 'লগইন') : tr('Set PIN & Continue', 'পিন সেভ ও প্রবেশ'),
            submitPin,
            gradient: true,
            busy: busy,
            icon: Icons.arrow_forward),
        if (hasPin) ...[
          Center(
              child: text(tr('OR INSTANT ACCESS', 'অথবা তাৎক্ষণিক প্রবেশ'),
                  size: 10, color: p.muted, spacing: 1.2)),
          InkWell(
              onTap: submitPin,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.fingerprint,
                        color: Color(0xFF0D9488), size: 20),
                    hgap(8),
                    Flexible(
                        child: text(
                            tr('Login with Face ID / Fingerprint',
                                'ফেস আইডি / ফিঙ্গারপ্রিন্ট দিয়ে লগইন'),
                            size: 12.5,
                            color: p.muted))
                  ]))),
        ],
        Divider(height: 1, color: p.border),
        Center(
            child: link(tr('← Change Number', '← নম্বর পরিবর্তন'),
                () => go(AuthStep.mobile),
                color: p.muted))
      ]));
  Widget otpCard() {
    final phone = (signupMobile.text.isEmpty ? mobile.text : signupMobile.text)
        .replaceAll(' ', '');
    final masked = phone.length >= 10
        ? '+880 ${phone.substring(0, 4)} •••• ${phone.substring(phone.length - 3)}'
        : '+880 $phone';
    return panel(
        p,
        stack([
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2)))),
          Center(
              child: text(
                  success
                      ? tr('OTP Verified Successfully!',
                          'ওটিপি সফলভাবে যাচাই হয়েছে!')
                      : tr('Verify Mobile OTP', 'মোবাইল ওটিপি যাচাইকরণ'),
                  size: 19,
                  color: success ? p.primary : p.ink,
                  align: TextAlign.center)),
          if (!success) ...[
            Center(child: pill(masked, p.muted, size: 12)),
            Center(
                child: link(tr('✎ Change Number', '✎ নম্বর পরিবর্তন'),
                    () => go(AuthStep.mobile))),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                  height: 60,
                  child: Stack(children: [
                    Row(children: [
                      for (int i = 0; i < 6; i++)
                        Expanded(
                            child: Container(
                                margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                                height: 58,
                                decoration: BoxDecoration(
                                    color: otp.text.length > i
                                        ? const Color(0xFFF0FDFA)
                                        : p.ground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: error != null
                                            ? p.error
                                            : otp.text.length == i
                                                ? const Color(0xFF0D9488)
                                                : p.border,
                                        width: otp.text.length == i ? 2 : 1)),
                                child: Center(
                                    child: text(
                                        otp.text.length > i ? otp.text[i] : '·',
                                        size: 22,
                                        color: p.ink,
                                        family: 'monospace'))))
                    ]),
                    Positioned.fill(
                        child: Opacity(
                            opacity: .01,
                            child: TextField(
                                key: const Key('otp-input'),
                                controller: otp,
                                focusNode: otpFocus,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6)
                                ],
                                onChanged: (value) {
                                  setState(() => error = null);
                                  if (value.length == 6) verifyOtp();
                                },
                                decoration: const InputDecoration(
                                    border: InputBorder.none))))
                  ])),
            if (error != null) errorText(),
            Center(
                child: text(
                    tr('Resend code in ${countdown}s',
                        'আবার কোড পাঠান ${countdown}s'),
                    size: 12,
                    color: p.muted)),
            primary(tr('Verify Code', 'কোড যাচাই করুন'),
                otp.text.length == 4 ? verifyOtp : null,
                gradient: true, busy: busy, icon: Icons.chevron_right),
            Center(
                child: text(tr("Didn't receive code?", "কোড পাননি?"),
                    size: 11, color: p.muted)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              link(tr('Resend via SMS', 'এসএমএস পাঠান'), () {
                if (countdown == 0) {
                  otp.clear();
                  resetTimer();
                }
              }),
              hgap(16),
              link('WhatsApp', () {
                if (countdown == 0) {
                  otp.clear();
                  resetTimer();
                }
              })
            ])
          ] else
            const Center(
                child: Icon(Icons.check_circle,
                    color: Color(0xFF10B981), size: 70)),
        ], spacing: 16, align: CrossAxisAlignment.stretch),
        radius: 28,
        padding: 22,
        shadow: true);
  }

  Widget registrationCard() => card(stack([
        text(tr('Customer Registration', 'নতুন গ্রাহক নিবন্ধন'),
            size: 18, color: p.ink),
        field(
            tr('Full Name (as on NID)',
                'পূর্ণ নাম (জাতীয় পরিচয়পত্র অনুযায়ী)'),
            name,
            p,
            hint: 'e.g. Tanvir Ahmed',
            onChanged: (_) => setState(() {})),
        field(tr('Mobile Number', 'মোবাইল নম্বর'), signupMobile, p,
            hint: '01755892401',
            keyboard: TextInputType.phone,
            onChanged: (_) => setState(() {})),
        field(tr('Email Address (Optional)', 'ইমেইল ঠিকানা (ঐচ্ছিক)'), email, p,
            hint: 'tanvir@gmail.com'),
        field(
            tr('6-Digit Security PIN', '৬-ডিজিটের সিকিউরিটি পিন'), signupPin, p,
            hint: '••••••',
            keyboard: TextInputType.number,
            maxLength: 6,
            onChanged: (_) => setState(() {})),
        Row(children: [
          Checkbox(
              value: consent,
              onChanged: (v) => setState(() => consent = v ?? false)),
          Expanded(
              child: text(
                  tr('I agree to Terms & Regulatory consents.',
                      'আমি বাংলাদেশ ব্যাংকের শর্তাবলী ও নীতিমালায় সম্মত।'),
                  size: 12,
                  color: p.muted))
        ]),
        primary(
            tr('Continue with OTP Verification', 'ওটিপি যাচাই ও নিবন্ধন করুন'),
            consent &&
                    name.text.isNotEmpty &&
                    signupMobile.text.isNotEmpty &&
                    signupPin.text.length == 6
                ? () => go(AuthStep.otp)
                : null),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
              child: text(
                  tr('Already have an account? ', 'ইতিমধ্যে অ্যাকাউন্ট আছে? '),
                  size: 12,
                  color: p.muted)),
          link(tr('Sign In', 'লগইন করুন'), () => go(AuthStep.mobile))
        ])
      ]));
  Widget forgotCard() => card(stack([
        text(tr('Forgot Security PIN?', 'সিকিউরিটি পিন ভুলে গেছেন?'),
            size: 18, color: p.ink),
        text(
            tr('Enter your registered mobile number to reset your PIN.',
                'পিন রিসেট করতে নিবন্ধিত মোবাইল নম্বর দিন।'),
            size: 12,
            color: p.muted),
        field(tr('Mobile Number', 'মোবাইল নম্বর'), mobile, p,
            keyboard: TextInputType.phone),
        primary(tr('Request OTP', 'ওটিপি পাঠান'), () => go(AuthStep.otp),
            gradient: true),
        Center(
            child: link(tr('Back to Sign In', 'লগইনে ফিরে যান'),
                () => go(AuthStep.mobile)))
      ]));
}

class AuthBackground extends CustomPainter {
  final bool dark;
  const AuthBackground(this.dark);
  @override
  void paint(Canvas c, Size s) {
    c.drawColor(Color(dark ? 0xFF0B0F19 : 0xFFF8FAFC), BlendMode.src);
    final bounds = Offset.zero & s;
    c.drawRect(
        bounds,
        Paint()
          ..shader = RadialGradient(
              center: const Alignment(0, -.85),
              radius: 1.1,
              colors: [
                const Color(0xFF0D9488).withValues(alpha: dark ? 0.15 : 0.08),
                const Color(0xFF0284C7).withValues(alpha: dark ? 0.08 : 0.03),
                Colors.transparent
              ]).createShader(bounds));
  }

  @override
  bool shouldRepaint(covariant AuthBackground old) => dark != old.dark;
}
