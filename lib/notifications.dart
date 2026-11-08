import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'dialogs.dart';
import 'profile.dart';

/// Retains the original notification screen, which is not a bottom-nav tab.
class NotificationsScreen extends StatefulWidget {
  final ToriState state;
  const NotificationsScreen({super.key, required this.state});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory filter = NotificationCategory.ALL;
  ToriState get s => widget.state;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final p = Palette(s.dark);
        final filtered = s.notifications
            .where((n) =>
                filter == NotificationCategory.ALL || n.category == filter)
            .toList();
        return Scaffold(
            backgroundColor: p.ground,
            appBar: AppBar(
                title: text(s.tr('Notifications', 'নোটিফিকেশন'),
                    size: 20, color: p.ink),
                actions: [
                  IconButton(
                      tooltip: 'Mark all read',
                      onPressed: () => s.markRead(null),
                      icon: const Icon(Icons.done_all)),
                  IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh))
                ]),
            body: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: tabs(
                      [
                        s.tr('All', 'সকল'),
                        s.tr('Transactions', 'লেনদেন'),
                        'MFI',
                        s.tr('Offers', 'অফার')
                      ],
                      filter.index,
                      (i) => setState(
                          () => filter = NotificationCategory.values[i]),
                      p)),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      children: [
                    if (filtered.isEmpty) ...[
                      gap(60),
                      Icon(Icons.notifications_none, size: 70, color: p.muted),
                      gap(),
                      Center(
                          child: text(
                              s.tr('No notifications yet',
                                  'কোনো নোটিফিকেশন নেই'),
                              color: p.muted)),
                      Center(
                          child: link(
                              s.tr('Show All', 'সব দেখুন'),
                              () => setState(
                                  () => filter = NotificationCategory.ALL)))
                    ],
                    for (final group in NotificationGroup.values)
                      if (filtered.any((n) => n.group == group)) ...[
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: text(
                                s.bengali
                                    ? ['আজ', 'গতকাল', 'আগের'][group.index]
                                    : group.name,
                                size: 11,
                                color: p.muted,
                                spacing: 1)),
                        for (final n in filtered.where((n) => n.group == group))
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Dismissible(
                                  key: ValueKey(n.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) =>
                                      s.deleteNotification(n.id),
                                  background: Container(
                                      color: p.error,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.all(20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white)),
                                  child: InkWell(
                                      onTap: () => action(n),
                                      child: panel(
                                          p,
                                          stack([
                                            Row(children: [
                                              Icon(icon(n.iconType),
                                                  color: n.isUrgent
                                                      ? p.error
                                                      : p.primary,
                                                  size: 28),
                                              hgap(12),
                                              Expanded(
                                                  child: text(
                                                      s.bengali
                                                          ? n.titleBn
                                                          : n.titleEn,
                                                      size: 14,
                                                      color: p.ink)),
                                              if (n.isUnread)
                                                Icon(Icons.circle,
                                                    color: p.primary, size: 7)
                                            ]),
                                            text(
                                                s.bengali ? n.bodyBn : n.bodyEn,
                                                size: 12,
                                                color: p.muted),
                                            if (n.highlightAmount != null)
                                              text(n.highlightAmount!,
                                                  size: 18, color: p.ink),
                                            Row(children: [
                                              Expanded(
                                                  child: text(
                                                      s.bengali
                                                          ? n.timeAgoBn
                                                          : n.timeAgoEn,
                                                      size: 10,
                                                      color: p.muted)),
                                              if (n.tagTextEn != null)
                                                pill(
                                                    s.bengali
                                                        ? n.tagTextBn ??
                                                            n.tagTextEn!
                                                        : n.tagTextEn!,
                                                    n.isUrgent
                                                        ? p.error
                                                        : p.primary)
                                            ]),
                                            if (n.actionLabelEn != null)
                                              link(
                                                  s.bengali
                                                      ? n.actionLabelBn ??
                                                          n.actionLabelEn!
                                                      : n.actionLabelEn!,
                                                  () => action(n))
                                          ]),
                                          radius: 18))))
                      ]
                  ]))
            ]));
      });
  IconData icon(String value) => switch (value) {
        'calendar_clock' => Icons.calendar_month,
        'savings' => Icons.savings,
        'arrow_down' => Icons.call_received,
        'fingerprint' => Icons.fingerprint,
        'offer' => Icons.local_offer,
        'overdue' => Icons.warning_amber,
        'kyc' => Icons.verified_user,
        'loan' => Icons.request_quote,
        'security' => Icons.shield,
        _ => Icons.swap_horiz
      };
  void action(NotificationItem n) {
    s.markRead(n.id);
    switch (n.actionType) {
      case 'pay_now':
        showMfiPayment(context, s);
      case 'kyc':
        showKyc(context, s);
      case 'security':
        showSecurity(context, s);
      default:
        showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: Text(s.bengali ? n.titleBn : n.titleEn),
                    content: Text(s.bengali ? n.bodyBn : n.bodyEn),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s.tr('Close', 'বন্ধ করুন')))
                    ]));
    }
  }
}
