import 'package:flutter/material.dart';
import 'state.dart';
import 'ui.dart';
import 'dialogs.dart';
import 'profile_setup.dart';

Future<void> openKyc(BuildContext context, ToriState state) => openPage<void>(
    context,
    state,
    state.tr('Submit KYC', 'কেওয়াইসি জমা দিন'),
    (_) => KycSetupPage(state: state));

class KycAccessNotice extends StatelessWidget {
  final ToriState state;
  final String status;
  const KycAccessNotice({super.key, required this.state, required this.status});
  @override
  Widget build(BuildContext context) => pageBody([
        text(state.tr('Approved KYC is required to send money or cash out.',
            'টাকা পাঠানো বা ক্যাশ আউটের জন্য কেওয়াইসি অনুমোদিত হতে হবে।')),
        text(kycLabel(state, status)),
        if (status != 'Pending')
          primary(state.tr('Submit KYC', 'কেওয়াইসি জমা দিন'), () async {
            await openKyc(context, state);
            if (context.mounted) Navigator.of(context).pop();
          }),
      ]);
}
