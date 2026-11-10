// Dart equivalents of all models in the original Android app.
enum AccountCategory { ALL, SAVINGS, DEPOSIT, LOANS }

enum AccountType { SAVINGS_CURRENT, SHARIAH_DPS, FIXED_DEPOSIT_FDR, MFI_LOAN }

enum NotificationCategory { ALL, TRANSACTIONS, MFI, OFFERS }

enum NotificationGroup { TODAY, YESTERDAY, EARLIER }

enum TransferChannel { TORI_ACCOUNT, BKASH_NAGAD, BANK_TRANSFER }

enum AppNavTab { HOME, ACCOUNTS, PAYMENTS, PROFILE }

enum AppThemeMode { SYSTEM, LIGHT, DARK }

enum ProfileDialogType {
  MY_PROFILE,
  KYC_STATUS,
  NOMINEE_INFO,
  SECURITY_PIN,
  BIOMETRICS,
  CHANGE_LANGUAGE,
  HELP_SUPPORT,
  PRIVACY_POLICY,
  TERMS_CONDITIONS,
  EDIT_PHOTO,
  MY_CARD
}

class AccountItem {
  final String id;
  final String titleEn;
  final String titleBn;
  final String accountNumber;
  final AccountType type;
  final double balance;
  final String subtitleEn;
  final String subtitleBn;
  final String tagText;
  final String? interestRate;
  final double progressPercent;
  final int installmentsCompleted;
  final int totalInstallments;
  final double? sanctionedAmount;
  final double repaidPercent;
  final double? nextInstallmentAmount;
  final String? nextDueDateEn;
  final String? nextDueDateBn;
  final String? maturityDateEn;
  final double? accruedProfit;
  final bool isAutoRenewal;
  const AccountItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.accountNumber,
    required this.type,
    required this.balance,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.tagText,
    this.interestRate = null,
    this.progressPercent = 0.0,
    this.installmentsCompleted = 0,
    this.totalInstallments = 0,
    this.sanctionedAmount = null,
    this.repaidPercent = 0.0,
    this.nextInstallmentAmount = null,
    this.nextDueDateEn = null,
    this.nextDueDateBn = null,
    this.maturityDateEn = null,
    this.accruedProfit = null,
    this.isAutoRenewal = false,
  });
  AccountItem copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? accountNumber,
    AccountType? type,
    double? balance,
    String? subtitleEn,
    String? subtitleBn,
    String? tagText,
    String? interestRate,
    double? progressPercent,
    int? installmentsCompleted,
    int? totalInstallments,
    double? sanctionedAmount,
    double? repaidPercent,
    double? nextInstallmentAmount,
    String? nextDueDateEn,
    String? nextDueDateBn,
    String? maturityDateEn,
    double? accruedProfit,
    bool? isAutoRenewal,
  }) =>
      AccountItem(
        id: id ?? this.id,
        titleEn: titleEn ?? this.titleEn,
        titleBn: titleBn ?? this.titleBn,
        accountNumber: accountNumber ?? this.accountNumber,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        subtitleEn: subtitleEn ?? this.subtitleEn,
        subtitleBn: subtitleBn ?? this.subtitleBn,
        tagText: tagText ?? this.tagText,
        interestRate: interestRate ?? this.interestRate,
        progressPercent: progressPercent ?? this.progressPercent,
        installmentsCompleted:
            installmentsCompleted ?? this.installmentsCompleted,
        totalInstallments: totalInstallments ?? this.totalInstallments,
        sanctionedAmount: sanctionedAmount ?? this.sanctionedAmount,
        repaidPercent: repaidPercent ?? this.repaidPercent,
        nextInstallmentAmount:
            nextInstallmentAmount ?? this.nextInstallmentAmount,
        nextDueDateEn: nextDueDateEn ?? this.nextDueDateEn,
        nextDueDateBn: nextDueDateBn ?? this.nextDueDateBn,
        maturityDateEn: maturityDateEn ?? this.maturityDateEn,
        accruedProfit: accruedProfit ?? this.accruedProfit,
        isAutoRenewal: isAutoRenewal ?? this.isAutoRenewal,
      );
}

class TransactionItem {
  final String id;
  final String titleEn;
  final String titleBn;
  final String timeEn;
  final String timeBn;
  final String categoryEn;
  final String categoryBn;
  final double amount;
  final bool isCredit;
  final String statusEn;
  final String statusBn;
  final String iconType;
  final String txnId;
  final DateTime? occurredAt;
  final double? netAmount;
  final double? fee;
  final String? note;
  const TransactionItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.timeEn,
    required this.timeBn,
    required this.categoryEn,
    required this.categoryBn,
    required this.amount,
    required this.isCredit,
    required this.statusEn,
    required this.statusBn,
    required this.iconType,
    required this.txnId,
    this.occurredAt,
    this.netAmount,
    this.fee,
    this.note = null,
  });
  factory TransactionItem.fromJson(Map<String, dynamic> data) {
    double number(dynamic value) => double.tryParse('$value') ?? 0;
    final at = DateTime.tryParse(data['occurred_at'] ?? '')?.toLocal();
    final time = at == null
        ? ''
        : '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    return TransactionItem(
        id: data['id'],
        titleEn: data['title_en'],
        titleBn: data['title_bn'],
        timeEn: time,
        timeBn: time,
        categoryEn: data['category_en'],
        categoryBn: data['category_bn'],
        amount: number(data['amount']),
        isCredit: data['is_credit'] == true,
        statusEn: data['status_en'],
        statusBn: data['status_bn'],
        iconType: data['icon_type'] ?? 'transfer',
        txnId: data['reference'],
        note: data['note'],
        occurredAt: at,
        netAmount: number(data['net_amount']),
        fee: number(data['fee']));
  }
  TransactionItem copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? timeEn,
    String? timeBn,
    String? categoryEn,
    String? categoryBn,
    double? amount,
    bool? isCredit,
    String? statusEn,
    String? statusBn,
    String? iconType,
    String? txnId,
    String? note,
  }) =>
      TransactionItem(
        id: id ?? this.id,
        titleEn: titleEn ?? this.titleEn,
        titleBn: titleBn ?? this.titleBn,
        timeEn: timeEn ?? this.timeEn,
        timeBn: timeBn ?? this.timeBn,
        categoryEn: categoryEn ?? this.categoryEn,
        categoryBn: categoryBn ?? this.categoryBn,
        amount: amount ?? this.amount,
        isCredit: isCredit ?? this.isCredit,
        statusEn: statusEn ?? this.statusEn,
        statusBn: statusBn ?? this.statusBn,
        iconType: iconType ?? this.iconType,
        txnId: txnId ?? this.txnId,
        occurredAt: occurredAt,
        netAmount: netAmount,
        fee: fee,
        note: note ?? this.note,
      );
}

class FavoriteContact {
  final String id;
  final String name;
  final String shortName;
  final String number;
  final String serviceName;
  final String badgeLabel;
  final int badgeColorHex;
  final String? imageUrl;
  final String? initials;
  const FavoriteContact({
    required this.id,
    required this.name,
    required this.shortName,
    required this.number,
    required this.serviceName,
    required this.badgeLabel,
    required this.badgeColorHex,
    this.imageUrl = null,
    this.initials = null,
  });
  FavoriteContact copyWith({
    String? id,
    String? name,
    String? shortName,
    String? number,
    String? serviceName,
    String? badgeLabel,
    int? badgeColorHex,
    String? imageUrl,
    String? initials,
  }) =>
      FavoriteContact(
        id: id ?? this.id,
        name: name ?? this.name,
        shortName: shortName ?? this.shortName,
        number: number ?? this.number,
        serviceName: serviceName ?? this.serviceName,
        badgeLabel: badgeLabel ?? this.badgeLabel,
        badgeColorHex: badgeColorHex ?? this.badgeColorHex,
        imageUrl: imageUrl ?? this.imageUrl,
        initials: initials ?? this.initials,
      );
}

class NotificationItem {
  final String id;
  final String titleEn;
  final String titleBn;
  final String timeAgoEn;
  final String timeAgoBn;
  final String bodyEn;
  final String bodyBn;
  final NotificationCategory category;
  final NotificationGroup group;
  final String groupDateEn;
  final bool isUnread;
  final String iconType;
  final String? actionType;
  final String? refAccount;
  final String? txnId;
  final String? highlightAmount;
  final String? tagTextEn;
  final String? tagTextBn;
  final String? tagType;
  final String? actionLabelEn;
  final String? actionLabelBn;
  final bool isUrgent;
  const NotificationItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.timeAgoEn,
    required this.timeAgoBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.category,
    required this.group,
    required this.groupDateEn,
    required this.isUnread,
    required this.iconType,
    this.actionType = null,
    this.refAccount = null,
    this.txnId = null,
    this.highlightAmount = null,
    this.tagTextEn = null,
    this.tagTextBn = null,
    this.tagType = null,
    this.actionLabelEn = null,
    this.actionLabelBn = null,
    this.isUrgent = false,
  });
  NotificationItem copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? timeAgoEn,
    String? timeAgoBn,
    String? bodyEn,
    String? bodyBn,
    NotificationCategory? category,
    NotificationGroup? group,
    String? groupDateEn,
    bool? isUnread,
    String? iconType,
    String? actionType,
    String? refAccount,
    String? txnId,
    String? highlightAmount,
    String? tagTextEn,
    String? tagTextBn,
    String? tagType,
    String? actionLabelEn,
    String? actionLabelBn,
    bool? isUrgent,
  }) =>
      NotificationItem(
        id: id ?? this.id,
        titleEn: titleEn ?? this.titleEn,
        titleBn: titleBn ?? this.titleBn,
        timeAgoEn: timeAgoEn ?? this.timeAgoEn,
        timeAgoBn: timeAgoBn ?? this.timeAgoBn,
        bodyEn: bodyEn ?? this.bodyEn,
        bodyBn: bodyBn ?? this.bodyBn,
        category: category ?? this.category,
        group: group ?? this.group,
        groupDateEn: groupDateEn ?? this.groupDateEn,
        isUnread: isUnread ?? this.isUnread,
        iconType: iconType ?? this.iconType,
        actionType: actionType ?? this.actionType,
        refAccount: refAccount ?? this.refAccount,
        txnId: txnId ?? this.txnId,
        highlightAmount: highlightAmount ?? this.highlightAmount,
        tagTextEn: tagTextEn ?? this.tagTextEn,
        tagTextBn: tagTextBn ?? this.tagTextBn,
        tagType: tagType ?? this.tagType,
        actionLabelEn: actionLabelEn ?? this.actionLabelEn,
        actionLabelBn: actionLabelBn ?? this.actionLabelBn,
        isUrgent: isUrgent ?? this.isUrgent,
      );
}

class UserProfile {
  final String fullName;
  final String memberType;
  final bool isVerified;
  final String mfiId;
  final String photoUrl;
  final String mobileNumber;
  final String email;
  final String address;
  final String mfiBranch;
  final String relationship;
  final String kycStatus;
  final int rewardPoints;
  const UserProfile({
    required this.fullName,
    required this.memberType,
    required this.isVerified,
    required this.mfiId,
    required this.photoUrl,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.mfiBranch,
    required this.relationship,
    required this.kycStatus,
    this.rewardPoints = 0,
  });
  UserProfile copyWith({
    String? fullName,
    String? memberType,
    bool? isVerified,
    String? mfiId,
    String? photoUrl,
    String? mobileNumber,
    String? email,
    String? address,
    String? mfiBranch,
    String? relationship,
    String? kycStatus,
    int? rewardPoints,
  }) =>
      UserProfile(
        fullName: fullName ?? this.fullName,
        memberType: memberType ?? this.memberType,
        isVerified: isVerified ?? this.isVerified,
        mfiId: mfiId ?? this.mfiId,
        photoUrl: photoUrl ?? this.photoUrl,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        email: email ?? this.email,
        address: address ?? this.address,
        mfiBranch: mfiBranch ?? this.mfiBranch,
        relationship: relationship ?? this.relationship,
        kycStatus: kycStatus ?? this.kycStatus,
        rewardPoints: rewardPoints ?? this.rewardPoints,
      );
}

class KycDetails {
  final String status;
  final String nidNumber;
  final String nidFrontUrl;
  final String nidBackUrl;
  final String selfieUrl;
  final String submissionDate;
  final String? reviewerMessage;
  const KycDetails({
    required this.status,
    required this.nidNumber,
    required this.nidFrontUrl,
    required this.nidBackUrl,
    required this.selfieUrl,
    required this.submissionDate,
    this.reviewerMessage = null,
  });
  KycDetails copyWith({
    String? status,
    String? nidNumber,
    String? nidFrontUrl,
    String? nidBackUrl,
    String? selfieUrl,
    String? submissionDate,
    String? reviewerMessage,
  }) =>
      KycDetails(
        status: status ?? this.status,
        nidNumber: nidNumber ?? this.nidNumber,
        nidFrontUrl: nidFrontUrl ?? this.nidFrontUrl,
        nidBackUrl: nidBackUrl ?? this.nidBackUrl,
        selfieUrl: selfieUrl ?? this.selfieUrl,
        submissionDate: submissionDate ?? this.submissionDate,
        reviewerMessage: reviewerMessage ?? this.reviewerMessage,
      );
}

class NomineeInfo {
  final String fullName;
  final String relationship;
  final String nidNumber;
  final String dob;
  final double sharePercentage;
  final String mobileNumber;
  final String requestStatus;
  const NomineeInfo({
    required this.fullName,
    required this.relationship,
    required this.nidNumber,
    required this.dob,
    required this.sharePercentage,
    required this.mobileNumber,
    required this.requestStatus,
  });
  NomineeInfo copyWith({
    String? fullName,
    String? relationship,
    String? nidNumber,
    String? dob,
    double? sharePercentage,
    String? mobileNumber,
    String? requestStatus,
  }) =>
      NomineeInfo(
        fullName: fullName ?? this.fullName,
        relationship: relationship ?? this.relationship,
        nidNumber: nidNumber ?? this.nidNumber,
        dob: dob ?? this.dob,
        sharePercentage: sharePercentage ?? this.sharePercentage,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        requestStatus: requestStatus ?? this.requestStatus,
      );
}

class SupportTicket {
  final String id;
  final String subject;
  final String category;
  final String description;
  final String status;
  final String createdDate;
  final bool hasAttachment;
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.description,
    required this.status,
    required this.createdDate,
    this.hasAttachment = false,
  });
  SupportTicket copyWith({
    String? id,
    String? subject,
    String? category,
    String? description,
    String? status,
    String? createdDate,
    bool? hasAttachment,
  }) =>
      SupportTicket(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        category: category ?? this.category,
        description: description ?? this.description,
        status: status ?? this.status,
        createdDate: createdDate ?? this.createdDate,
        hasAttachment: hasAttachment ?? this.hasAttachment,
      );
}

class PromoBanner {
  final String id;
  final String badgeEn;
  final String badgeBn;
  final String headlineEn;
  final String headlineBn;
  final String actionEn;
  final String actionBn;
  final List<int> bgGradient;
  final String illustrationType;
  const PromoBanner({
    required this.id,
    required this.badgeEn,
    required this.badgeBn,
    required this.headlineEn,
    required this.headlineBn,
    required this.actionEn,
    required this.actionBn,
    required this.bgGradient,
    required this.illustrationType,
  });
  PromoBanner copyWith({
    String? id,
    String? badgeEn,
    String? badgeBn,
    String? headlineEn,
    String? headlineBn,
    String? actionEn,
    String? actionBn,
    List<int>? bgGradient,
    String? illustrationType,
  }) =>
      PromoBanner(
        id: id ?? this.id,
        badgeEn: badgeEn ?? this.badgeEn,
        badgeBn: badgeBn ?? this.badgeBn,
        headlineEn: headlineEn ?? this.headlineEn,
        headlineBn: headlineBn ?? this.headlineBn,
        actionEn: actionEn ?? this.actionEn,
        actionBn: actionBn ?? this.actionBn,
        bgGradient: bgGradient ?? this.bgGradient,
        illustrationType: illustrationType ?? this.illustrationType,
      );
}
