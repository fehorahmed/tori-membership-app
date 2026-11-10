import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'seed_data.dart';
import 'services/dashboard_service.dart';
import 'services/profile_service.dart';

/// State and local transaction behaviour preserved from ToriRepository.kt.
class ToriState extends ChangeNotifier {
  // Matches ApiConfig.kt: the supplied app has no live banking endpoint.
  static const backendConfigured = false;
  bool online = true;
  String get transferUnavailable => tr(
      'Live MFI Backend API endpoint not provisioned (Source of Truth enforcement). Client-side execution disabled.',
      'সঞ্চয় ও লোন সার্ভার ব্যাকএন্ড এন্ডপয়েন্ট কনফিগার করা হয়নি (সততা নীতি লঙ্ঘন প্রতিরোধ)। ক্লায়েন্ট সাইড থেকে লেনদেন অনুমোদন নিষিদ্ধ।');
  String get loanUnavailable => tr(
      'Live MFI Loan payment endpoint not provisioned (Source of Truth enforcement).',
      'লোন কিস্তি পেমেন্ট সার্ভার এন্ডপয়েন্ট কনফিগার করা হয়নি (সততা নীতি লঙ্ঘন প্রতিরোধ)।');
  double balance = 160450;
  List<AccountItem> accounts = initialAccounts();
  List<TransactionItem> transactions = [];
  List<FavoriteContact> favorites = initialFavorites();
  List<NotificationItem> notifications = initialNotifications();
  List<SupportTicket> tickets = initialTickets();
  UserProfile profile = initialProfile();
  KycDetails kyc = initialKyc();
  Map<String, String> memberImageHeaders = {};
  NomineeInfo nominee = initialNominee();
  bool bengali = false, hidden = false, loggedIn = false;
  bool biometric = true, twoStep = false;
  AppThemeMode theme = AppThemeMode.LIGHT;
  AppNavTab tab = AppNavTab.HOME;
  AccountCategory accountFilter = AccountCategory.ALL;
  TransferChannel channel = TransferChannel.TORI_ACCOUNT;
  String recipient = '01719 283741', recipientName = 'Tanima H.', note = '';
  double amount = 15000;
  int timeframe = 1;
  String securityPin = '982341';
  SharedPreferences? _prefs;
  bool get dark => theme == AppThemeMode.DARK;
  String tr(String en, String bn) => bengali ? bn : en;
  String money(num value, {bool mask = false, bool decimals = true}) => mask &&
          hidden
      ? '••••••'
      : '৳ ${NumberFormat(decimals ? '#,##,##0.00' : '#,##,##0').format(value)}';
  double get assets => accounts
      .where((a) => a.type != AccountType.MFI_LOAN)
      .fold(0, (v, a) => v + a.balance);
  double get liabilities => accounts
      .where((a) => a.type == AccountType.MFI_LOAN)
      .fold(0, (v, a) => v + a.balance);
  double get income =>
      transactions.where((t) => t.isCredit).fold(0, (v, t) => v + t.amount);
  double get spending =>
      transactions.where((t) => !t.isCredit).fold(0, (v, t) => v + t.amount);
  Future<void> loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    bengali = _prefs?.getBool('is_bengali') ?? false;
    biometric = _prefs?.getBool('biometric_enabled') ?? true;
    twoStep = _prefs?.getBool('two_step_enabled') ?? false;
    theme = _prefs?.getString('theme_mode') == 'DARK'
        ? AppThemeMode.DARK
        : AppThemeMode.LIGHT;
    notifyListeners();
  }

  void changed() => notifyListeners();
  void setLanguage(bool value) {
    bengali = value;
    _prefs?.setBool('is_bengali', value);
    changed();
  }

  void toggleTheme() {
    theme = dark ? AppThemeMode.LIGHT : AppThemeMode.DARK;
    _prefs?.setString('theme_mode', theme.name);
    changed();
  }

  void setBiometric(bool value) {
    biometric = value;
    _prefs?.setBool('biometric_enabled', value);
    changed();
  }

  void setTwoStep(bool value) {
    twoStep = value;
    _prefs?.setBool('two_step_enabled', value);
    changed();
  }

  void navigate(AppNavTab value) {
    tab = value;
    changed();
  }

  bool dashboardLoading = false;
  String? dashboardError;
  int _memberEpoch = 0;

  void logout() {
    _memberEpoch++;
    dashboardLoading = false;
    dashboardError = null;
    transactions = [];
    loggedIn = false;
    changed();
  }

  bool verifyOtp(String value) => kDebugMode
      ? value == '1234' || value == '123456'
      : value.trim().length >= 4 && value.trim().length <= 6;
  bool verifyPin(String value) => kDebugMode
      ? value.length >= 4 && value.length <= 6
      : value == securityPin;
  void login() {
    _memberEpoch++;
    transactions = [];
    profile = profile.copyWith(
        fullName: '',
        mobileNumber: '',
        email: '',
        address: '',
        photoUrl: '',
        mfiId: '',
        mfiBranch: '',
        isVerified: false,
        kycStatus: 'Not submitted');
    kyc = const KycDetails(
        status: 'Not submitted',
        nidNumber: '',
        nidFrontUrl: '',
        nidBackUrl: '',
        selfieUrl: '',
        submissionDate: '');
    loggedIn = true;
    changed();
    loadDashboardData();
    loadMemberProfile();
  }

  void applyMemberProfile(Map<String, dynamic> data) {
    final details = data['kyc'] as Map<String, dynamic>? ?? {};
    final documents = details['documents'] is Map
        ? Map<String, dynamic>.from(details['documents'])
        : <String, dynamic>{};
    profile = profile.copyWith(
        fullName: data['name'] ?? '',
        mobileNumber: data['mobile_no'] ?? '',
        email: data['email'] ?? '',
        address: data['address'] ?? '',
        photoUrl: data['image'] ?? '',
        mfiId: data['member_no'] ?? '',
        isVerified: data['is_verified'] == true,
        kycStatus: details['status'] ?? 'Not submitted');
    kyc = KycDetails(
        status: details['status'] ?? 'Not submitted',
        nidNumber: details['nid_number'] ?? '',
        nidFrontUrl: documents['nid_front'] ?? '',
        nidBackUrl: documents['nid_back'] ?? '',
        selfieUrl: documents['selfie'] ?? '',
        submissionDate: details['submitted_at'] ?? '',
        reviewerMessage: details['reviewer_message']);
    changed();
  }

  Future<Map<String, dynamic>> loadMemberProfile(
      {ProfileService? service}) async {
    final client = service ?? ProfileService();
    final result = await client.fetch(language: bengali ? 'bn' : 'en');
    if (service == null) client.close();
    if (result['success'] == true) {
      memberImageHeaders = await ProfileService.headers();
      applyMemberProfile(result['data']);
    }
    return result;
  }

  Future<void> loadDashboardData() async {
    final epoch = _memberEpoch;
    dashboardLoading = true;
    dashboardError = null;
    changed();
    final res = await DashboardService.fetchDashboardData();
    if (epoch != _memberEpoch) return;
    dashboardLoading = false;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final cust = data['customer'];
      final summary = data['summary'];
      transactions = (data['recent_transactions'] as List? ?? [])
          .map(
              (row) => TransactionItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();

      // Update Profile with Real Backend Customer Data
      if (cust != null) {
        profile = profile.copyWith(
          fullName: cust['name'] ?? profile.fullName,
          mobileNumber: cust['mobile_no'] ?? profile.mobileNumber,
          email: cust['email'] ?? profile.email,
          mfiId: cust['member_no'] ?? profile.mfiId,
        );
      }

      // Update Real Savings Balance
      if (summary != null) {
        balance = ((summary['available_savings_balance'] ??
                    summary['savings_balance']) as num?)
                ?.toDouble() ??
            balance;
        _syncBalance();
      }

      changed();
    } else {
      dashboardError = tr('Could not refresh transactions. Please retry.',
          'লেনদেন রিফ্রেশ করা যায়নি। আবার চেষ্টা করুন।');
      changed();
    }
  }

  void updateRecipient(String value) {
    recipient = value;
    recipientName = '';
    for (final f in favorites) {
      if (f.number.replaceAll(' ', '') == value.replaceAll(' ', '').trim()) {
        recipientName = f.shortName;
        break;
      }
    }
    final clean = value.replaceAll(' ', '').trim();
    if (recipientName.isEmpty && clean.length == 11 && clean.startsWith('01'))
      recipientName = 'Verified User';
    changed();
  }

  void selectFavorite(FavoriteContact f) {
    recipient = f.number;
    recipientName = f.shortName;
    channel = switch (f.serviceName) {
      'bKash' || 'Nagad' => TransferChannel.BKASH_NAGAD,
      'TORI Pay' ||
      'TORI' ||
      'MFI Bank' ||
      'MFI' =>
        TransferChannel.TORI_ACCOUNT,
      _ => TransferChannel.BANK_TRANSFER,
    };
    changed();
  }

  String get channelName =>
      ['TORI Pay', 'bKash/Nagad', 'NPSB Bank Transfer'][channel.index];
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  void _syncBalance() {
    accounts = accounts
        .map((a) => a.type == AccountType.SAVINGS_CURRENT
            ? a.copyWith(balance: balance)
            : a)
        .toList();
  }

  TransactionItem _transaction(String en, String bn, double value, bool credit,
      String icon, String category,
      {String? memo}) {
    final t = TransactionItem(
        id: _id(),
        titleEn: en,
        titleBn: bn,
        timeEn: 'Just now • $channelName',
        timeBn: 'এইমাত্র • $channelName',
        categoryEn: category,
        categoryBn: category,
        amount: value,
        isCredit: credit,
        statusEn: credit ? 'Credited' : 'Completed',
        statusBn: credit ? 'জমা হয়েছে' : 'সফল হয়েছে',
        iconType: icon,
        txnId: 'TR-${1000000 + Random().nextInt(9000000)}',
        note: memo);
    transactions = [t, ...transactions];
    return t;
  }

  void _notification(String en, String bn, String body, TransactionItem txn,
      NotificationCategory category) {
    notifications = [
      NotificationItem(
          id: _id(),
          titleEn: en,
          titleBn: bn,
          timeAgoEn: 'Just now',
          timeAgoBn: 'এইমাত্র',
          bodyEn: body,
          bodyBn: body,
          category: category,
          group: NotificationGroup.TODAY,
          groupDateEn: 'Today',
          isUnread: true,
          iconType: txn.iconType,
          actionType: 'details',
          txnId: txn.txnId),
      ...notifications
    ];
  }

  TransactionItem? transfer() {
    if (amount <= 0 || amount > balance) return null;
    balance -= amount;
    _syncBalance();
    final name =
        recipientName.isEmpty ? 'Transfer to $recipient' : recipientName;
    final t = _transaction(
        name, name, amount, false, 'transfer', 'Transfer Out',
        memo: note);
    _notification(
        'Transfer Sent Successfully',
        'স্থানান্তর সফল হয়েছে',
        'Transferred ${money(amount)} to $name ($recipient). Zero fee applied.',
        t,
        NotificationCategory.TRANSACTIONS);
    changed();
    return t;
  }

  bool payInstallment([double value = 12500]) {
    if (value <= 0 || balance < value) return false;
    balance -= value;
    _syncBalance();
    accounts = accounts.map((a) {
      if (a.type != AccountType.MFI_LOAN) return a;
      final remaining = max(0.0, a.balance - value),
          sanctioned = a.sanctionedAmount ?? 200000;
      return a.copyWith(
          balance: remaining,
          repaidPercent: (sanctioned - remaining) / sanctioned * 100,
          nextDueDateEn: '15 Nov 2024',
          nextDueDateBn: '১৫ নভেম্বর ২০২৪');
    }).toList();
    final t = _transaction(
        'MFI Installment Repayment',
        'ক্ষুদ্রঋণ কিস্তি পরিশোধ',
        value,
        false,
        'installment',
        'Loan Recovery');
    _notification(
        'MFI Installment Paid',
        'কিস্তি পরিশোধ সফল',
        'Paid ${money(value)} for Agri-Business Loan. Next installment due on 15 Nov.',
        t,
        NotificationCategory.MFI);
    changed();
    return true;
  }

  void addMoney(double value, String source) {
    balance += value;
    _syncBalance();
    _transaction('Add Money ($source)', 'টাকা জমা ($source)', value, true,
        'transfer', 'Account Inflow');
    changed();
  }

  bool openDeposit(
      AccountType type, String title, double value, String tenure) {
    if (balance < value) return false;
    balance -= value;
    _syncBalance();
    final dps = type == AccountType.SHARIAH_DPS;
    accounts = [
      ...accounts,
      AccountItem(
          id: '${dps ? 'dps' : 'fdr'}_${_id()}',
          titleEn: title,
          titleBn: dps ? 'মাসিক শরীয়াহ ডিপিএস' : 'ফিক্সড ডিপোজিট রিসিট',
          accountNumber: '•••• ${1000 + Random().nextInt(9000)}',
          type: type,
          balance: value,
          subtitleEn: dps
              ? 'Monthly: ${money(value)} / mo'
              : '$tenure Term • 10.5% p.a.',
          subtitleBn: dps
              ? 'মাসিক: ${money(value)} / মাস'
              : '$tenure মেয়াদ • ১০.৫% বার্ষিক',
          tagText: dps ? 'DPS-$tenure' : 'FDR',
          interestRate: dps ? '9.5% p.a.' : '10.5% p.a.',
          progressPercent: dps ? 2.8 : 0,
          installmentsCompleted: dps ? 1 : 0,
          totalInstallments: dps ? 36 : 0,
          accruedProfit: dps ? null : 0,
          maturityDateEn: dps ? null : '10 Oct 2027',
          isAutoRenewal: !dps)
    ];
    changed();
    return true;
  }

  void markRead(String? id) {
    notifications = notifications
        .map((n) => id == null || n.id == id ? n.copyWith(isUnread: false) : n)
        .toList();
    changed();
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    changed();
  }

  void supportTicket(
      String subject, String category, String description, bool attached) {
    tickets = [
      SupportTicket(
          id: 'TCK-${1000 + Random().nextInt(9000)}',
          subject: subject,
          category: category,
          description: description,
          status: 'Open',
          createdDate: 'Today',
          hasAttachment: attached),
      ...tickets
    ];
    changed();
  }
}
