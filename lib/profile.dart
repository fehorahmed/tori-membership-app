import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dialogs.dart';
import 'legal_copy.dart';
import 'member_card.dart';
import 'profile_setup.dart';

class ProfileScreen extends StatelessWidget {
  final ToriState state;
  const ProfileScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state, p = Palette(s.dark);
    return SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                roundIcon(Icons.arrow_back, p,
                    onTap: () => s.navigate(AppNavTab.HOME)),
                hgap(12),
                text(s.tr('My Profile', 'আমার প্রোফাইল'),
                    size: 20, color: p.ink, family: 'PlusJakartaSans')
              ])),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: stack([
                    profileHero(context, s, p),
                    group(s.tr('PERSONAL INFORMATION', 'ব্যক্তিগত তথ্য'), p, [
                      profileRow(
                          s.tr('My Profile', 'আমার প্রোফাইল'),
                          Icons.person_outline,
                          p,
                          () => showMyProfile(context, s)),
                      profileRow(s.tr('KYC Status', 'কেওয়াইসি স্ট্যাটাস'),
                          Icons.shield_outlined, p, () => showKyc(context, s),
                          badge: kycLabel(s, s.profile.kycStatus)),
                      profileRow(
                          s.tr('Nominee Information', 'নমিনী তথ্য'),
                          Icons.groups_outlined,
                          p,
                          null)
                    ]),
                    group(s.tr('MY CARD', 'ডিজিটাল কার্ড'), p, [
                      profileRow(s.tr('My Card', 'আমার ডিজিটাল কার্ড'),
                          Icons.credit_card, p, () => showCard(context, s),
                          subtitle: s.tr('Membership card details',
                              'মেম্বারশিপ কার্ডের বিস্তারিত'))
                    ]),
                    group(
                        s.tr('SECURITY & SETTINGS', 'নিরাপত্তা ও সেটিংস'), p, [
                      profileRow(
                          s.tr('Security & Access', 'সিকিউরিটি ও এক্সেস'),
                          Icons.admin_panel_settings_outlined,
                          p,
                          null,
                          badge: 'SECURE HUB'),
                      SwitchListTile(
                          value: s.dark,
                          onChanged: (_) => s.toggleTheme(),
                          secondary:
                              Icon(Icons.dark_mode_outlined, color: p.muted),
                          title: text(s.tr('Dark Mode', 'ডার্ক মোড'),
                              color: p.ink),
                          subtitle: text(
                              s.dark
                                  ? s.tr('Swiss Corporate Dark Theme active',
                                      'সুইস কর্পোরেট ডার্ক থিম সক্রিয়')
                                  : s.tr('Swiss Corporate Light Theme active',
                                      'সুইস কর্পোরেট লাইট থিম সক্রিয়'),
                              size: 11,
                              color: p.muted)),
                      profileRow(s.tr('Change Language', 'ভাষা পরিবর্তন'),
                          Icons.language, p, () => showLanguage(context, s),
                          subtitle: s.bengali
                              ? 'বাংলা / English'
                              : 'English (US) / বাংলা')
                    ]),
                    group(s.tr('SUPPORT & LEGAL', 'সাপোর্ট ও লিগ্যাল'), p, [
                      profileRow(
                          s.tr('Help & Support', 'সহযোগিতা'),
                          Icons.phone_outlined,
                          p,
                          null,
                          badge: 'Priority Support'),
                      profileRow(s.tr('Privacy Policy', 'প্রাইভেসি পলিসি'),
                          Icons.gavel, p, () => showLegal(context, s, false)),
                      profileRow(
                          s.tr('Terms of Service', 'টার্মস ও কন্ডিশন'),
                          Icons.description_outlined,
                          p,
                          () => showLegal(context, s, true))
                    ]),
                    SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                            onPressed: s.logout,
                            style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF1F2),
                                foregroundColor: const Color(0xFFBE123C),
                                side:
                                    const BorderSide(color: Color(0xFFFECDD3)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            icon: const Icon(Icons.logout, size: 18),
                            label: text('Log Out / প্রস্থান করুন',
                                size: 14, color: const Color(0xFFBE123C)))),
                    Center(
                        child: text(
                            s.tr(
                                'Secured with 256-bit Swiss Banking Grade Encryption',
                                '২৫৬-বিট সুইস ব্যাংকিং গ্রেড এনক্রিপশন দ্বারা সুরক্ষিত'),
                            size: 11,
                            color: p.muted,
                            align: TextAlign.center)),
                  ], spacing: 18)))
        ]));
  }
}

Widget group(String title, Palette p, List<Widget> children) => stack([
      text(title, size: 11, color: p.muted, spacing: .7),
      panel(
          p,
          Material(
            type: MaterialType.transparency,
            child: Column(children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 62, color: p.border),
                children[i]
              ]
            ]),
          ),
          padding: 0,
          radius: 18)
    ], spacing: 8);
Widget profileRow(String title, IconData icon, Palette p, VoidCallback? tap,
        {String? subtitle, String? badge, Color? tint}) =>
    Opacity(opacity: tap == null ? .4 : 1, child: InkWell(
        onTap: tap,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: (tint ?? p.primary).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border)),
                  child: Icon(icon, color: tint ?? p.primary, size: 18)),
              hgap(14),
              Expanded(
                  child: stack([
                text(title, color: tint ?? p.ink, size: 14),
                if (subtitle != null) text(subtitle, size: 11, color: p.muted),
                if (badge != null)
                  Align(
                      alignment: Alignment.centerLeft,
                      child: pill(badge, p.primary, size: 9))
              ], spacing: 4)),
              Icon(Icons.chevron_right, size: 18, color: p.muted)
            ]))));

Future<bool> verifyUpdate(
    BuildContext context, ToriState s, String title) async {
  final otp = TextEditingController(), pin = TextEditingController();
  int step = 0;
  String? error;
  final result = await openPage<bool>(
      context,
      s,
      title,
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark);
            return pageBody([
              Center(
                  child: Icon(
                      step == 0 ? Icons.sms_outlined : Icons.lock_outline,
                      size: 48,
                      color: p.primary)),
              text(
                  step == 0
                      ? s.tr('Step 1: Mobile OTP Verification',
                          'ধাপ ১: ওটিপি যাচাইকরণ')
                      : s.tr('Step 2: Enter Security PIN',
                          'ধাপ ২: সিকিউরিটি পিন নিশ্চিতকরণ'),
                  size: 20,
                  color: p.ink),
              field(
                  step == 0
                      ? 'OTP'
                      : s.tr('Security PIN', 'ট্রানজেকশন / সিকিউরিটি পিন'),
                  step == 0 ? otp : pin,
                  p,
                  keyboard: TextInputType.number,
                  maxLength: 6,
                  obscure: step == 1),
              if (error != null) text(error!, size: 12, color: p.error),
              primary(
                  step == 0
                      ? s.tr('Verify Code', 'কোড যাচাই করুন')
                      : s.tr('Confirm Security PIN', 'নিশ্চিত করুন'), () {
                if (step == 0) {
                  if (s.verifyOtp(otp.text))
                    set(() {
                      step = 1;
                      error = null;
                    });
                  else
                    set(() =>
                        error = s.tr('Invalid OTP code.', 'ভুল ওটিপি কোড।'));
                } else if (s.verifyPin(pin.text))
                  Navigator.pop(ctx, true);
                else
                  set(() => error =
                      s.tr('Invalid Security PIN.', 'ভুল সিকিউরিটি পিন।'));
              })
            ]);
          }));
  otp.dispose();
  pin.dispose();
  return result ?? false;
}

Future<void> showMyProfile(BuildContext context, ToriState s) async {
  await openPage<void>(context, s, s.tr('My Profile', 'আমার প্রোফাইল'),
      (_) => ProfileDetailsPage(state: s));
}

Future<void> showKyc(BuildContext context, ToriState s) async {
  await openPage<void>(context, s, s.tr('Profile verification', 'প্রোফাইল যাচাই'),
      (_) => KycSetupPage(state: s));
}

Future<void> showNominee(BuildContext context, ToriState s) async {
  final values = [
    s.nominee.fullName,
    s.nominee.relationship,
    s.nominee.nidNumber,
    s.nominee.dob,
    s.nominee.sharePercentage.toString(),
    s.nominee.mobileNumber
  ].map((v) => TextEditingController(text: v)).toList();
  bool editing = false;
  await openPage<void>(
      context,
      s,
      s.tr('Nominee Information', 'নমিনী তথ্য'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark), n = s.nominee;
            final labels = [
              'Legal Nominee Name',
              'Relationship / সম্পর্ক',
              'National ID Number (NID)',
              'Date of Birth',
              'Share Percentage',
              'Mobile Number'
            ];
            return pageBody([
              panel(
                  p,
                  stack([
                    Center(
                        child: CircleAvatar(
                            radius: 36,
                            backgroundColor: p.primary.withValues(alpha: .1),
                            child: Icon(Icons.person,
                                color: p.primary, size: 40))),
                    Center(child: text(n.fullName, size: 22, color: p.ink)),
                    Center(
                        child: pill(
                            n.requestStatus == 'Approved'
                                ? 'Approved / অনুমোদিত'
                                : n.requestStatus,
                            p.primary)),
                    text('Verification Details', size: 16, color: p.ink),
                    text('National ID Biometrics', size: 11, color: p.muted),
                    for (int i = 0; i < 6; i++)
                      editing
                          ? field(labels[i], values[i], p)
                          : infoRow(
                              labels[i],
                              [
                                n.fullName,
                                n.relationship,
                                n.nidNumber,
                                n.dob,
                                '${n.sharePercentage}%',
                                n.mobileNumber
                              ][i],
                              p)
                  ])),
              primary(
                  editing
                      ? s.tr('Submit Update Request', 'পরিবর্তনের আবেদন')
                      : s.tr('Update Nominee', 'নমিনী পরিবর্তন'), () async {
                if (!editing) {
                  set(() => editing = true);
                  return;
                }
                if (await verifyUpdate(
                    ctx,
                    s,
                    s.tr('Verify Nominee Request',
                        'নমিনী পরিবর্তন নিশ্চিতকরণ'))) {
                  s.nominee = NomineeInfo(
                      fullName: values[0].text,
                      relationship: values[1].text,
                      nidNumber: values[2].text,
                      dob: values[3].text,
                      sharePercentage: double.tryParse(values[4].text) ?? 100,
                      mobileNumber: values[5].text,
                      requestStatus: 'Pending Review');
                  s.changed();
                  if (ctx.mounted) set(() => editing = false);
                }
              })
            ]);
          }));
  for (final c in values) c.dispose();
}

Future<void> showSecurity(BuildContext context, ToriState s) async =>
    openPage<void>(
        context, s, s.tr('Account Security & Access', 'সিকিউরিটি ও এক্সেস'),
        (ctx) {
      final p = Palette(s.dark);
      return pageBody([
        text(
            s.tr('Manage your digital identity & multi-factor authentication',
                'আপনার ডিজিটাল আইডেন্টিটি এবং মাল্টি-ফ্যাক্টর অথেন্টিকেশন পরিচালনা করুন'),
            size: 13,
            color: p.muted),
        group(s.tr('SECURITY CONTROLS', 'সিকিউরিটি কন্ট্রোল'), p, [
          SwitchListTile(
              value: s.twoStep,
              onChanged: s.setTwoStep,
              title: text(s.tr('2-Step Verification', '২-ধাপ যাচাইকরণ'),
                  color: p.ink),
              subtitle: text(
                  s.tr('Enhanced security for high-value transactions',
                      'উচ্চমূল্যের লেনদেনের জন্য অতিরিক্ত নিরাপত্তা'),
                  size: 11,
                  color: p.muted),
              secondary: Icon(Icons.shield_outlined, color: p.primary)),
          SwitchListTile(
              value: s.biometric,
              onChanged: s.setBiometric,
              title: text(s.tr('Biometric Login', 'বায়োমেট্রিক লগইন'),
                  color: p.ink),
              subtitle: text('Face ID & Fingerprint authentication',
                  size: 11, color: p.muted),
              secondary: Icon(Icons.fingerprint, color: p.primary)),
          profileRow(s.tr('Transaction PIN', 'ট্রানজেকশন পিন'),
              Icons.pin_outlined, p, () => showChangePin(ctx, s),
              subtitle: s.tr('Change your 6-digit security PIN',
                  'আপনার ৬-ডিজিটের সিকিউরিটি পিন পরিবর্তন করুন')),
          profileRow(
              s.tr('Login Password', 'লগইন পাসওয়ার্ড'),
              Icons.password,
              p,
              () => toast(ctx, 'Web Portal access required to change password'),
              subtitle: 'Update your web portal password')
        ]),
        group(s.tr('DEVICE & ACCESS', 'ডিভাইস ও এক্সেস'), p, [
          profileRow(
              s.tr('Active Sessions', 'সক্রিয় সেশন'), Icons.devices, p, () {},
              subtitle: s.tr('3 devices currently signed in',
                  '৩টি ডিভাইসে বর্তমানে সাইন ইন করা আছে')),
          profileRow(s.tr('Device Binding', 'ডিভাইস বাইন্ডিং'),
              Icons.phonelink_lock, p, () {},
              subtitle: s.tr('Securely bind this device to your MFI ID',
                  'আপনার এমএফআই আইডির সাথে এই ডিভাইসটি সুরক্ষিতভাবে যুক্ত করুন'))
        ]),
        group(s.tr('ADVANCED', 'অ্যাডভান্সড'), p, [
          profileRow(s.tr('Delete Account', 'অ্যাকাউন্ট মুছে ফেলুন'),
              Icons.delete_outline, p, () {},
              subtitle: s.tr('Permanently remove your digital banking access',
                  'স্থায়ীভাবে আপনার ডিজিটাল ব্যাংকিং এক্সেস সরিয়ে ফেলুন'),
              tint: p.error)
        ]),
        Center(
            child: text('PCI-DSS Level 1 & SOC2 Compliant',
                size: 11, color: p.muted)),
        Center(
            child: text(
                s.tr(
                    'TORI MFI Banking is secured as per MRA Guidelines',
                    'তোরী এমএফআই ব্যাংকিং সিস্টেম এমআরএ গাইডলাইন অনুযায়ী সুরক্ষিত'),
                size: 11,
                color: p.muted,
                align: TextAlign.center)),
        primary(s.tr('Save Security Settings', 'সেটিংস সংরক্ষণ করুন'),
            () => Navigator.pop(ctx))
      ]);
    });
Future<void> showChangePin(BuildContext context, ToriState s) async {
  final old = TextEditingController(),
      newPin = TextEditingController(),
      confirm = TextEditingController(),
      otp = TextEditingController();
  String? error;
  await openPage<void>(
      context,
      s,
      s.tr('Change Security PIN', 'সিকিউরিটি পিন পরিবর্তন'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark);
            return pageBody([
              Center(child: Icon(Icons.lock_reset, color: p.primary, size: 52)),
              text(
                  s.tr('Secure PIN Update Verification',
                      'সুরক্ষিত পিন পরিবর্তন যাচাইকরণ'),
                  size: 19,
                  color: p.ink),
              field(s.tr('Current PIN', 'বর্তমান পিন'), old, p,
                  keyboard: TextInputType.number, obscure: true, maxLength: 6),
              field(s.tr('New PIN', 'নতুন পিন'), newPin, p,
                  keyboard: TextInputType.number, obscure: true, maxLength: 6),
              field(
                  s.tr('Confirm New PIN', 'নতুন পিন নিশ্চিত করুন'), confirm, p,
                  keyboard: TextInputType.number, obscure: true, maxLength: 6),
              field('OTP', otp, p,
                  keyboard: TextInputType.number, maxLength: 6),
              if (error != null) text(error!, color: p.error, size: 12),
              primary(
                  s.tr('Update Security PIN', 'সিকিউরিটি পিন পরিবর্তন করুন'),
                  () {
                if (old.text != s.securityPin)
                  set(() => error =
                      s.tr('Current PIN is incorrect', 'বর্তমান পিন ভুল'));
                else if (!RegExp(r'^\d{4,6}$').hasMatch(newPin.text))
                  set(() => error =
                      s.tr('PIN must be 4–6 digits', 'পিন ৪–৬ ডিজিট হতে হবে'));
                else if (newPin.text != confirm.text)
                  set(() => error = s.tr('PINs do not match', 'পিন মিলছে না'));
                else if (otp.text.length != 6)
                  set(() =>
                      error = s.tr('Invalid OTP code.', 'ভুল ওটিপি কোড।'));
                else {
                  s.securityPin = newPin.text;
                  s.changed();
                  Navigator.pop(ctx);
                  toast(
                      context,
                      s.tr('Security PIN updated',
                          'সিকিউরিটি পিন পরিবর্তন হয়েছে'));
                }
              })
            ]);
          }));
  for (final c in [old, newPin, confirm, otp]) c.dispose();
}

Future<void> showLanguage(BuildContext context, ToriState s) async =>
    openPage<void>(
        context,
        s,
        s.tr('Change App Language', 'ভাষা নির্বাচন করুন'),
        (ctx) => pageBody([
              for (final bn in [false, true])
                RadioListTile<bool>(
                    value: bn,
                    groupValue: s.bengali,
                    onChanged: (v) => s.setLanguage(v!),
                    title: text(bn ? 'বাংলা' : 'English (US)', size: 18),
                    subtitle: Text(bn ? 'Bengali' : 'English')),
              primary(s.tr('Save Language', 'ভাষা সংরক্ষণ করুন'),
                  () => Navigator.pop(ctx))
            ]));
Future<void> showLegal(BuildContext context, ToriState s, bool terms) async {
  bool agreed = false;
  await openPage<void>(
      context,
      s,
      terms
          ? s.tr('Terms & Conditions', 'টার্মস ও কন্ডিশন')
          : s.tr('Privacy Policy', 'প্রাইভেসি পলিসি'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark), copy = terms ? termsCopy : privacyCopy;
            return pageBody([
              for (int i = 0; i < copy.length - (terms ? 2 : 1); i++)
                text(copy[i][s.bengali ? 1 : 0],
                    size: i == 0 ? 24 : (i >= 2 && i.isEven ? 16 : 12),
                    color: i == 1
                        ? p.primary
                        : i % 2 == 0
                            ? p.ink
                            : p.muted,
                    weight: i % 2 == 0 ? FontWeight.bold : FontWeight.w400),
              if (terms)
                CheckboxListTile(
                    value: agreed,
                    onChanged: (v) => set(() => agreed = v ?? false),
                    title: text(copy[copy.length - 2][s.bengali ? 1 : 0],
                        size: 12, color: p.ink)),
              primary(copy.last[s.bengali ? 1 : 0],
                  !terms || agreed ? () => Navigator.pop(ctx) : null)
            ]);
          }));
}

Widget profilePhoto(String source, {double size = 76, Map<String, String>? headers}) {
  Widget fallback() => SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.person, size: 40, color: Color(0xFF64748B)));
  if (source.startsWith('data:image/')) {
    try {
      return Image.memory(base64Decode(source.split(',').last),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    } catch (_) {
      return fallback();
    }
  }
  return Image.network(source,
      headers: headers,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback());
}

Widget profileHero(BuildContext context, ToriState s, Palette p) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: panel(
        p,
        Column(children: [
          Container(
              height: 3.5,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                Color(0xFF14B8A6),
                Color(0xFF0D9488),
                Color(0xFF10B981)
              ]))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(clipBehavior: Clip.none, children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: profilePhoto(s.profile.photoUrl, headers: s.memberImageHeaders)),
                      Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.primary,
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                              child: const Center(
                                  child: Icon(Icons.circle,
                                      size: 5, color: Colors.white)))),
                      Positioned(
                          bottom: -3,
                          right: -3,
                          child: InkWell(
                              onTap: () => showPhoto(context, s),
                              child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      color: p.primary,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                          color: Colors.white, width: 2)),
                                  child: const Icon(Icons.camera_alt,
                                      size: 13, color: Colors.white))))
                    ])),
                hgap(16),
                Expanded(
                    child: stack([
                  text(s.profile.fullName,
                      size: 18, color: p.ink, family: 'PlusJakartaSans'),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    pill('★ TORI Prime', const Color(0xFF0F766E), size: 11),
                    pill(kycLabel(s, s.profile.kycStatus),
                        s.profile.isVerified ? const Color(0xFF047857) : p.muted,
                        size: 11)
                  ]),
                  Row(children: [
                    Flexible(
                        child: text('MFI Id: ${s.profile.mfiId}',
                            size: 12, color: p.muted, family: 'monospace')),
                    IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: s.profile.mfiId));
                          toast(context, 'MFI ID copied to clipboard');
                        },
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.copy, size: 14, color: p.primary))
                  ])
                ], spacing: 4))
              ]))
        ]),
        padding: 0,
        radius: 18));
Future<void> showPhoto(BuildContext context, ToriState s) => showKyc(context, s);

Future<void> showCard(BuildContext context, ToriState s) async {
  await openPage<void>(context, s, s.tr('My Card', 'আমার কার্ড'),
      (_) => MemberCardPage(state: s));
}

Future<void> showSupport(BuildContext context, ToriState s) async {
  int selected = 0;
  final search = TextEditingController(),
      subject = TextEditingController(),
      category = TextEditingController(text: 'MFI Loan'),
      description = TextEditingController();
  await openPage<void>(
      context,
      s,
      s.tr('Support Overview', 'সহযোগিতা ও হেল্পডেস্ক'),
      (ctx) => StatefulBuilder(builder: (ctx, set) {
            final p = Palette(s.dark);
            return pageBody([
              Row(children: [
                Expanded(
                    child: pill(
                        '● 24/7 Priority Desk • সহায়তা কেন্দ্র', p.primary,
                        size: 10)),
                hgap(8),
                text('256-Bit Encrypted', size: 9, color: p.muted)
              ]),
              tabs([
                'FAQ',
                s.tr('Create Ticket', 'টিকিট তৈরি'),
                s.tr('History', 'ইতিহাস')
              ], selected, (i) => set(() => selected = i), p),
              if (selected == 0) ...[
                field('', search, p,
                    hint: s.tr('Search questions, MFI loans...',
                        'প্রশ্ন বা প্রসঙ্গ অনুসন্ধান করুন...'),
                    suffix: const Icon(Icons.search),
                    onChanged: (_) => set(() {})),
                text(s.tr('POPULAR TOPICS', 'জনপ্রিয় প্রসঙ্গ'),
                    size: 11, color: p.muted, spacing: 1),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final topic in [
                        'NID / KYC',
                        'DPS Profit Rate',
                        'MFS Transfer',
                        'Security PIN'
                      ])
                        Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: pill(topic, p.primary, size: 11))
                    ])),
                Row(children: [
                  for (final item in [
                    ('Live Chat', '~2m response', Icons.chat_bubble),
                    (
                      '16216 Desk',
                      s.tr('Toll-Free Helpline', 'টোল-ফ্রি হেল্পলাইন'),
                      Icons.call
                    ),
                    (
                      'Email Desk',
                      s.tr('Official Support', 'অফিসিয়াল সাপোর্ট'),
                      Icons.mark_email_read
                    )
                  ])
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: panel(
                                p,
                                stack([
                                  Icon(item.$3, color: p.primary, size: 22),
                                  text(item.$1,
                                      size: 12,
                                      color: p.ink,
                                      align: TextAlign.center),
                                  text(item.$2,
                                      size: 9,
                                      color: p.muted,
                                      align: TextAlign.center)
                                ],
                                    spacing: 8,
                                    align: CrossAxisAlignment.center),
                                padding: 10,
                                radius: 12)))
                ]),
                sectionTitle(
                    s.tr('Frequently Asked Questions', 'সাধারণ জিজ্ঞাসা'), p,
                    action: s.tr('3 Key Topics', '৩ টি প্রধান প্রশ্ন')),
                for (final faq in [
                  [
                    'Savings & DPS',
                    '৩ মিনিট সময় লাগে',
                    'কিভাবে সঞ্চয়ী হিসাব খুলবেন?',
                    'How to open a Savings Account?',
                    "তোরী অ্যাপের 'হিসাব' সেকশনে গিয়ে নতুন ডিপিএস বা এফডিআর কয়েক ক্লিকেই খুলতে পারবেন।"
                  ],
                  [
                    'MFI Loan',
                    '০% অতিরিক্ত ফি',
                    'ক্ষুদ্রঋণ কিস্তি কিভাবে পরিশোধ করবেন?',
                    'How to pay Microfinance Installment?',
                    "হোম স্ক্রিনের 'পেমেন্ট' অথবা লোন অ্যাকাউন্ট ডিটেইলস থেকে রিয়েলটাইমে অটো-ডেবিট বা ম্যানুয়ালি কিস্তি দেওয়া যায়।"
                  ],
                  [
                    'E-Statement',
                    'PDF & Email Delivery',
                    'পাসবুক ও স্টেটমেন্ট ডাউনলোড করবেন কিভাবে?',
                    'How to download Passbook & Statement?',
                    "অ্যাকাউন্টস স্ক্রিন থেকে 'স্টেটমেন্ট' ট্যাবে গিয়ে যেকোনো তারিখ রেঞ্জের স্টেটমেন্ট পিডিএফ হিসেবে সেভ করুন।"
                  ]
                ])
                  panel(
                      p,
                      ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          shape: const Border(),
                          title: stack([
                            pill(faq[0], p.primary),
                            text(faq[2], size: 14, color: p.ink),
                            text(faq[3], size: 11, color: p.muted)
                          ], spacing: 6),
                          children: [text(faq[4], size: 12, color: p.muted)]),
                      radius: 16),
                panel(
                    p,
                    Row(children: [
                      CircleAvatar(
                          radius: 24,
                          backgroundColor: p.primary.withValues(alpha: .12),
                          child: Icon(Icons.person, color: p.primary)),
                      hgap(12),
                      Expanded(
                          child: stack([
                        text('MFI Field Officers Active',
                            size: 13, color: p.ink),
                        text(
                            'আমাদের প্রতিনিধিরা তাৎক্ষণিক সহায়তায় নিয়োজিত আছেন',
                            size: 11,
                            color: p.muted)
                      ], spacing: 4)),
                      pill('Online', p.primary, size: 9)
                    ])),
                panel(
                    p,
                    stack([
                      text('Still need help?', size: 16, color: p.ink),
                      text(
                          'আপনার সমস্যার সরাসরি সমাধান পেতে একটি টিকিট তৈরি করুন',
                          size: 12,
                          color: p.muted),
                      primary(s.tr('Create Support Ticket', 'টিকিট তৈরি করুন'),
                          () => set(() => selected = 1))
                    ]),
                    color: p.raised),
              ],
              if (selected == 1)
                panel(
                    p,
                    stack([
                      text(s.tr('Create Support Ticket', 'টিকিট তৈরি করুন'),
                          size: 18, color: p.ink),
                      field(s.tr('Ticket Subject', 'বিষয়'), subject, p),
                      field(s.tr('Category', 'ক্যাটাগরি'), category, p),
                      field(
                          s.tr('Description / Complaint Message',
                              'বিস্তারিত বর্ণনা'),
                          description,
                          p),
                      secondary(
                          s.tr('Attach Document / Screenshot',
                              'সংযুক্তি যুক্ত করুন (স্ক্রিনশট)'),
                          () {},
                          p),
                      primary(s.tr('Submit Support Ticket', 'টিকিট জমা দিন'),
                          () {
                        if (subject.text.trim().isEmpty) return;
                        s.supportTicket(subject.text, category.text,
                            description.text, false);
                        subject.clear();
                        description.clear();
                        set(() => selected = 2);
                        showSuccess(ctx, s,
                            message:
                                'Support ticket ${s.tickets.first.id} created successfully.');
                      })
                    ])),
              if (selected == 2) ...[
                for (final ticket in s.tickets)
                  panel(
                      p,
                      stack([
                        Row(children: [
                          Expanded(
                              child:
                                  text(ticket.id, size: 11, color: p.primary)),
                          pill(
                              ticket.status,
                              ticket.status == 'Open'
                                  ? const Color(0xFFD97706)
                                  : p.primary)
                        ]),
                        text(ticket.subject, size: 15, color: p.ink),
                        text(ticket.description, size: 12, color: p.muted),
                        text('Created: ${ticket.createdDate}',
                            size: 10, color: p.muted)
                      ], spacing: 8)),
                if (s.tickets.isEmpty)
                  Center(
                      child: text(
                          "No Support Tickets\nYou haven't created any support tickets yet.",
                          color: p.muted,
                          align: TextAlign.center))
              ]
            ]);
          }));
  for (final c in [search, subject, category, description]) c.dispose();
}
