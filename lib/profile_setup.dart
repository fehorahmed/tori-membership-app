import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dialogs.dart';
import 'services/profile_service.dart';
import 'state.dart';
import 'ui.dart';

String kycLabel(ToriState s, String status) => switch (status) {
      'Pending' => s.tr('Awaiting review', 'যাচাইয়ের অপেক্ষায়'),
      'Verified' => s.tr('Verified', 'যাচাইকৃত'),
      'Rejected' => s.tr('Rejected', 'প্রত্যাখ্যাত'),
      'Needs resubmission' =>
        s.tr('Please submit KYC again', 'আবার কেওয়াইসি জমা দিন'),
      _ => s.tr('Not submitted', 'জমা দেওয়া হয়নি'),
    };

class ProfileDetailsPage extends StatefulWidget {
  final ToriState state;
  final ProfileService? service;
  const ProfileDetailsPage({super.key, required this.state, this.service});
  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late final service = widget.service ?? ProfileService();
  final name = TextEditingController(),
      email = TextEditingController(),
      address = TextEditingController();
  bool loading = true, saving = false, loaded = false;
  String? error;
  ToriState get s => widget.state;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final result = await s.loadMemberProfile(service: service);
    if (!mounted) return;
    setState(() {
      loading = false;
      loaded = result['success'] == true;
      if (loaded) {
        name.text = s.profile.fullName;
        email.text = s.profile.email;
        address.text = s.profile.address;
      } else {
        error = result['message'];
      }
    });
  }

  Future<void> save() async {
    if (saving) return;
    if (name.text.trim().isEmpty) {
      setState(() => error = s.tr('Enter your full name.', 'পূর্ণ নাম লিখুন।'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final result = await service.update(
        name: name.text,
        email: email.text,
        address: address.text,
        language: s.bengali ? 'bn' : 'en');
    if (!mounted) return;
    setState(() => saving = false);
    if (result['success'] == true) {
      s.applyMemberProfile(result['data']);
      toast(context, s.tr('Profile saved.', 'প্রোফাইল সংরক্ষিত হয়েছে।'));
    } else {
      setState(() => error = result['message']);
    }
  }

  @override
  void dispose() {
    if (widget.service == null) service.close();
    name.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette(s.dark);
    if (loading) return const Center(child: CircularProgressIndicator());
    return pageBody([
      if (error != null) text(error!, color: p.error),
      if (!loaded) primary(s.tr('Retry', 'আবার চেষ্টা করুন'), load),
      if (loaded) ...[
        infoRow(
            s.tr('Mobile number', 'মোবাইল নম্বর'), s.profile.mobileNumber, p),
        infoRow(s.tr('Member ID', 'সদস্য নম্বর'), s.profile.mfiId, p),
        if (['Pending', 'Verified'].contains(s.kyc.status)) ...[
          infoRow(s.tr('Full name', 'পূর্ণ নাম'), name.text, p),
          text(
              s.tr(
                  'Contact your branch to change your name after submitting KYC.',
                  'কেওয়াইসি জমা দেওয়ার পর নাম পরিবর্তনের জন্য আপনার শাখায় যোগাযোগ করুন।'),
              color: p.muted),
        ] else
          field(s.tr('Full name', 'পূর্ণ নাম'), name, p, maxLength: 255),
        field(s.tr('Email (optional)', 'ইমেইল (ঐচ্ছিক)'), email, p,
            keyboard: TextInputType.emailAddress, maxLength: 255),
        field(s.tr('Address', 'ঠিকানা'), address, p, lines: 3, maxLength: 2000),
        primary(
            s.tr('Save profile', 'প্রোফাইল সংরক্ষণ করুন'), saving ? null : save,
            busy: saving),
        infoRow(s.tr('KYC status', 'কেওয়াইসি অবস্থা'),
            kycLabel(s, s.kyc.status), p),
        secondary(s.tr('Selfie & NID verification', 'সেলফি ও এনআইডি যাচাই'),
            () async {
          await openPage<void>(
              context,
              s,
              s.tr('Profile verification', 'প্রোফাইল যাচাই'),
              (_) => KycSetupPage(state: s));
          if (mounted) load();
        }, p),
      ],
    ]);
  }
}

class KycSetupPage extends StatefulWidget {
  final ToriState state;
  final ProfileService? service;
  const KycSetupPage({super.key, required this.state, this.service});
  @override
  State<KycSetupPage> createState() => _KycSetupPageState();
}

class _KycSetupPageState extends State<KycSetupPage> {
  late final service = widget.service ?? ProfileService();
  final nid = TextEditingController();
  final files = <String, XFile>{};
  final previews = <String, Uint8List>{};
  Map<String, String> imageHeaders = {};
  bool loading = true, saving = false, picking = false, loaded = false;
  String? error;
  ToriState get s => widget.state;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.service == null) service.close();
    nid.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final result = await s.loadMemberProfile(service: service);
    try {
      imageHeaders = await ProfileService.headers();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      loading = false;
      loaded = result['success'] == true;
      if (loaded) {
        nid.text = s.kyc.nidNumber;
      } else {
        error = result['message'];
      }
    });
  }

  Future<void> pick(String kind, ImageSource source) async {
    if (picking || saving) return;
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
          source: source,
          preferredCameraDevice:
              kind == 'selfie' ? CameraDevice.front : CameraDevice.rear,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 88);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        if (bytes.length > 5 * 1024 * 1024) {
          setState(() => error = s.tr('Each image must be 5 MB or smaller.',
              'প্রতিটি ছবি সর্বোচ্চ ৫ এমবি হতে পারবে।'));
        } else {
          setState(() {
            files[kind] = file;
            previews[kind] = bytes;
          });
        }
      }
    } catch (_) {
      if (mounted)
        setState(() => error = s.tr(
            'Unable to open the camera or photo library. Check permissions and try again.',
            'ক্যামেরা বা গ্যালারি খোলা যায়নি। অনুমতি পরীক্ষা করে আবার চেষ্টা করুন।'));
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> submit() async {
    if (saving || picking) return;
    if (!RegExp(r'^(?:[0-9]{10}|[0-9]{13}|[0-9]{17})$')
        .hasMatch(nid.text.trim())) {
      setState(() => error = s.tr('Enter a 10, 13 or 17 digit NID number.',
          '১০, ১৩ বা ১৭ সংখ্যার এনআইডি নম্বর লিখুন।'));
      return;
    }
    if (files.length != 3) {
      setState(() => error = s.tr(
          'Take a selfie and add both sides of your NID.',
          'সেলফি তুলুন এবং এনআইডির সামনে ও পেছনের ছবি যোগ করুন।'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final result = await service.submitKyc(
        nidNumber: nid.text.trim(),
        selfie: files['selfie']!,
        front: files['nid_front']!,
        back: files['nid_back']!,
        language: s.bengali ? 'bn' : 'en');
    if (!mounted) return;
    setState(() => saving = false);
    if (result['success'] == true) {
      files.clear();
      previews.clear();
      toast(context, result['message']);
      await load();
    } else {
      setState(() => error = result['message']);
    }
  }

  Widget document(String kind, String title, String existing) {
    final p = Palette(s.dark);
    final editable = s.kyc.status != 'Pending';
    final disabled = saving || picking;
    return panel(
        p,
        stack([
          text(title, color: p.ink, size: 16),
          if (previews[kind] != null)
            Image.memory(previews[kind]!, height: 170, fit: BoxFit.contain)
          else if (existing.isNotEmpty)
            Image.network(existing,
                headers: imageHeaders,
                height: 170,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => text(
                    s.tr('Unable to load image.', 'ছবি লোড করা যায়নি।'),
                    color: p.muted)),
          if (editable) ...[
            secondary(
                kind == 'selfie'
                    ? s.tr('Take selfie', 'সেলফি তুলুন')
                    : s.tr('Take photo', 'ছবি তুলুন'),
                disabled ? null : () => pick(kind, ImageSource.camera),
                p),
            if (kind != 'selfie')
              secondary(s.tr('Upload from gallery', 'গ্যালারি থেকে আপলোড করুন'),
                  disabled ? null : () => pick(kind, ImageSource.gallery), p),
          ],
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette(s.dark);
    if (loading) return const Center(child: CircularProgressIndicator());
    return pageBody([
      if (error != null) text(error!, color: p.error),
      if (!loaded) primary(s.tr('Retry', 'আবার চেষ্টা করুন'), load),
      if (loaded) ...[
        text(kycLabel(s, s.kyc.status), size: 22, color: p.ink),
        if (s.kyc.reviewerMessage?.isNotEmpty == true)
          text(s.kyc.reviewerMessage!, color: p.ink),
        if (s.kyc.status == 'Pending')
          text(
              s.tr('Your documents have been submitted for review.',
                  'আপনার ডকুমেন্টগুলো যাচাইয়ের জন্য জমা হয়েছে।'),
              color: p.muted)
        else ...[
          text(
              s.tr(
                  'Take a camera selfie and add the front and back of your NID separately. Each image: JPG, PNG or WebP, up to 5 MB.',
                  'ক্যামেরায় সেলফি তুলুন এবং এনআইডির সামনে ও পেছনের ছবি আলাদাভাবে যোগ করুন। প্রতিটি ছবি: JPG, PNG বা WebP, সর্বোচ্চ ৫ এমবি।'),
              color: p.muted),
          field(s.tr('NID number', 'এনআইডি নম্বর'), nid, p,
              keyboard: TextInputType.number, maxLength: 17),
        ],
        document(
            'selfie', s.tr('Camera selfie', 'ক্যামেরা সেলফি'), s.kyc.selfieUrl),
        document('nid_front', s.tr('NID — Front', 'এনআইডি — সামনে'),
            s.kyc.nidFrontUrl),
        document(
            'nid_back', s.tr('NID — Back', 'এনআইডি — পেছনে'), s.kyc.nidBackUrl),
        if (s.kyc.status != 'Pending')
          primary(s.tr('Submit for verification', 'যাচাইয়ের জন্য জমা দিন'),
              saving || picking ? null : submit,
              busy: saving),
      ],
    ]);
  }
}
