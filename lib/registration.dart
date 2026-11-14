import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'state.dart';
import 'ui.dart';
import 'profile.dart' show showLegal;

class RegistrationScreen extends StatefulWidget {
  final ToriState state;
  const RegistrationScreen({super.key, required this.state});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      mobile = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController(),
      referral = TextEditingController(),
      otp = TextEditingController(),
      pin = TextEditingController(),
      pinConfirmation = TextEditingController();
  List<Map<String, dynamic>> branches = [];
  int? branch;
  int step = 0, countdown = 0;
  bool consent = false, busy = false, loading = true, showPassword = false;
  String? error, registrationToken, verificationToken;
  Timer? timer;
  String get language => widget.state.bengali ? 'bn' : 'en';
  String tr(String en, String bn) => widget.state.tr(en, bn);
  Palette get p => Palette(widget.state.dark);

  @override
  void initState() {
    super.initState();
    loadBranches();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in [
      name,
      mobile,
      email,
      password,
      confirmation,
      referral,
      otp,
      pin,
      pinConfirmation
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadBranches() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await AuthService.client.get(
        Uri.parse('${ApiConfig.membershipAuthUrl}/registration/options'),
        headers: {'Accept': 'application/json', 'Accept-Language': language},
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true)
        throw StateError('Branches unavailable');
      if (mounted)
        setState(() {
          branches = List<Map<String, dynamic>>.from(data['data']['branches']);
        });
    } catch (_) {
      if (mounted)
        setState(() => error = tr('Unable to load branches. Please retry.',
            'শাখার তালিকা পাওয়া যায়নি। আবার চেষ্টা করুন।'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void startTimer() {
    timer?.cancel();
    countdown = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || step != 1) {
        t.cancel();
        return;
      }
      setState(() {
        if (countdown > 0)
          countdown--;
        else
          t.cancel();
      });
    });
  }

  Future<Map<String, dynamic>> send(
      String endpoint, Map<String, dynamic> body) async {
    final device = await AuthService.device(mobile.text);
    return AuthService.post(
        'register/$endpoint',
        {
          ...device,
          ...body,
          if (registrationToken != null)
            'registration_token': registrationToken,
        },
        language);
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (step == 0 && !consent) {
      setState(() => error = tr('Please accept the terms to continue.',
          'এগিয়ে যেতে শর্তাবলিতে সম্মতি দিন।'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      Map<String, dynamic> result;
      if (step == 0) {
        result = await send('initiate', {
          'name': name.text.trim(),
          'mobile_no': AuthService.normalizeMobile(mobile.text),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'branch_id': branch,
          'password': password.text,
          'password_confirmation': confirmation.text,
          'terms_accepted': consent,
          'referral_code':
              referral.text.trim().isEmpty ? null : referral.text.trim(),
        });
      } else if (step == 1) {
        result = await send('verify-otp', {'otp': otp.text});
      } else {
        result = await send('complete', {
          'verification_token': verificationToken,
          'pin': pin.text,
          'pin_confirmation': pinConfirmation.text
        });
      }
      if (!mounted) return;
      if (result['success'] != true) {
        setState(() => error = result['message'] ??
            tr('Registration failed.', 'নিবন্ধন করা যায়নি।'));
        return;
      }
      if (step == 0) {
        setState(() {
          registrationToken = result['data']['registration_token'];
          step = 1;
          password.clear();
          confirmation.clear();
          if (result['data']['debug_otp'] != null)
            otp.text = result['data']['debug_otp'].toString();
          startTimer();
        });
      } else if (step == 1) {
        setState(() {
          verificationToken = result['data']['verification_token'];
          step = 2;
          otp.clear();
        });
        timer?.cancel();
      } else {
        await AuthService.saveLogin(result, mobile.text);
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.state.login();
      }
    } catch (_) {
      if (mounted)
        setState(() => error = tr(
            'Unable to confirm registration. Retry or sign in if it completed.',
            'নিবন্ধনের ফল নিশ্চিত করা যায়নি। আবার চেষ্টা করুন অথবা নিবন্ধন হয়ে থাকলে লগইন করুন।'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (busy || countdown > 0) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await send('resend', {});
      if (!mounted) return;
      setState(() {
        if (result['success'] == true) {
          otp.clear();
          if (result['data']['debug_otp'] != null)
            otp.text = result['data']['debug_otp'].toString();
          startTimer();
        } else {
          error = result['message'];
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(String keyName, String label, TextEditingController controller,
      {bool secret = false,
      bool digits = false,
      int? length,
      TextInputType? keyboard,
      String? Function(String)? validate}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          key: Key(keyName),
          controller: controller,
          enabled: !busy,
          obscureText: secret && !showPassword,
          keyboardType: digits ? TextInputType.number : keyboard,
          inputFormatters: digits
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(length ?? 6)
                ]
              : null,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: secret
                  ? IconButton(
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility))
                  : null),
          validator: (value) => validate?.call(value ?? ''),
        ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: p.ground,
        appBar: AppBar(title: Text(tr('Create an Account', 'নতুন অ্যাকাউন্ট'))),
        body: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
                key: form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('Step ${step + 1} of 3', 'ধাপ ${step + 1}/৩'),
                          style: TextStyle(color: p.muted)),
                      const SizedBox(height: 16),
                      if (step == 0) ...[
                        input(
                            'registration-name',
                            tr('Full Name (as on NID)',
                                'পূর্ণ নাম (NID অনুযায়ী)'),
                            name,
                            validate: (v) => v.trim().isEmpty
                                ? tr('Enter your name.', 'নাম দিন।')
                                : null),
                        input('registration-mobile',
                            tr('Mobile Number', 'মোবাইল নম্বর'), mobile,
                            keyboard: TextInputType.phone,
                            validate: (v) => RegExp(r'^01[3-9]\d{8}$')
                                    .hasMatch(AuthService.normalizeMobile(v))
                                ? null
                                : tr('Enter a valid BD mobile number.',
                                    'সঠিক বাংলাদেশি মোবাইল নম্বর দিন।')),
                        input('registration-email',
                            tr('Email (Optional)', 'ইমেইল (ঐচ্ছিক)'), email,
                            keyboard: TextInputType.emailAddress),
                        if (loading)
                          const Center(child: CircularProgressIndicator())
                        else if (branches.isEmpty)
                          TextButton(
                              onPressed: loadBranches,
                              child: Text(tr('Retry loading branches',
                                  'শাখার তালিকা আবার নিন')))
                        else
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DropdownButtonFormField<int>(
                                key: const Key('registration-branch'),
                                initialValue: branch,
                                isExpanded: true,
                                decoration: InputDecoration(
                                    labelText: tr('Branch', 'শাখা'),
                                    border: const OutlineInputBorder()),
                                items: branches
                                    .map((b) => DropdownMenuItem<int>(
                                        value: b['id'],
                                        child: Text(
                                            '${b['code'] ?? ''} ${b['name']}',
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: busy
                                    ? null
                                    : (value) => setState(() => branch = value),
                                validator: (v) => v == null
                                    ? tr('Select a branch.',
                                        'শাখা নির্বাচন করুন।')
                                    : null,
                              )),
                        input(
                            'registration-referral',
                            tr('Referral / Agent Code (Optional)',
                                'রেফারেল / এজেন্ট কোড (ঐচ্ছিক)'),
                            referral),
                        input(
                            'registration-password',
                            tr('Website Password', 'ওয়েবসাইট পাসওয়ার্ড'),
                            password,
                            secret: true,
                            validate: (v) => v.length < 8
                                ? tr('Use at least 8 characters.',
                                    'অন্তত ৮ অক্ষর দিন।')
                                : null),
                        input(
                            'registration-password-confirmation',
                            tr('Confirm Password', 'পাসওয়ার্ড নিশ্চিত করুন'),
                            confirmation,
                            secret: true,
                            validate: (v) => v != password.text
                                ? tr('Passwords do not match.',
                                    'পাসওয়ার্ড মেলেনি।')
                                : null),
                        Text(
                            tr('This password is required to log in to the website. Use your 6-digit PIN to sign in to the app.',
                                'এই পাসওয়ার্ড ওয়েবসাইটে লগইন করার জন্য প্রয়োজন হবে। অ্যাপে লগইন করতে আপনার ৬ সংখ্যার PIN ব্যবহার করুন।'),
                            style: TextStyle(color: p.muted)),
                        CheckboxListTile(
                            key: const Key('registration-consent'),
                            contentPadding: EdgeInsets.zero,
                            value: consent,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => consent = v ?? false),
                            title: Text(tr(
                                'I agree to the Terms and Privacy Policy.',
                                'আমি শর্তাবলি ও গোপনীয়তা নীতিতে সম্মত।'))),
                        Wrap(children: [
                          TextButton(
                              onPressed: () =>
                                  showLegal(context, widget.state, true),
                              child:
                                  Text(tr('Terms & Conditions', 'শর্তাবলি'))),
                          TextButton(
                              onPressed: () =>
                                  showLegal(context, widget.state, false),
                              child:
                                  Text(tr('Privacy Policy', 'গোপনীয়তা নীতি'))),
                        ]),
                      ] else if (step == 1) ...[
                        Text(tr(
                            'Enter the 6-digit code sent to ${AuthService.normalizeMobile(mobile.text)}.',
                            '${AuthService.normalizeMobile(mobile.text)} নম্বরে পাঠানো ৬ সংখ্যার কোড দিন।')),
                        const SizedBox(height: 16),
                        input('registration-otp', tr('OTP', 'ওটিপি'), otp,
                            digits: true,
                            validate: (v) => v.length != 6
                                ? tr('Enter the 6-digit OTP.',
                                    '৬ সংখ্যার ওটিপি দিন।')
                                : null),
                        TextButton(
                            onPressed: countdown == 0 && !busy ? resend : null,
                            child: Text(countdown > 0
                                ? tr('Resend in ${countdown}s',
                                    '${countdown} সেকেন্ড পরে আবার পাঠান')
                                : tr('Resend OTP', 'ওটিপি আবার পাঠান'))),
                      ] else ...[
                        Text(tr(
                            'Set your 6-digit app PIN. This is separate from your website password.',
                            'অ্যাপের জন্য ৬ সংখ্যার PIN দিন। এটি ওয়েবসাইটের পাসওয়ার্ড থেকে আলাদা।')),
                        const SizedBox(height: 16),
                        input(
                            'registration-pin', tr('App PIN', 'অ্যাপ PIN'), pin,
                            secret: true,
                            digits: true,
                            validate: (v) => v.length != 6
                                ? tr('Enter a 6-digit PIN.',
                                    '৬ সংখ্যার PIN দিন।')
                                : null),
                        input(
                            'registration-pin-confirmation',
                            tr('Confirm PIN', 'PIN নিশ্চিত করুন'),
                            pinConfirmation,
                            secret: true,
                            digits: true,
                            validate: (v) => v != pin.text
                                ? tr('PINs do not match.', 'PIN মেলেনি।')
                                : null),
                      ],
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child:
                                Text(error!, style: TextStyle(color: p.error))),
                      primary(
                          step == 0
                              ? tr('Send OTP', 'ওটিপি পাঠান')
                              : step == 1
                                  ? tr('Verify OTP', 'ওটিপি যাচাই করুন')
                                  : tr('Complete Registration',
                                      'নিবন্ধন সম্পন্ন করুন'),
                          busy || loading || (step == 0 && branches.isEmpty)
                              ? null
                              : submit,
                          busy: busy),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed:
                              busy ? null : () => Navigator.of(context).pop(),
                          child: Text(tr('Already registered? Sign in',
                              'নিবন্ধন হয়ে গেছে? লগইন করুন'))),
                    ])),
          )),
        )),
      );
}
