/// Mirrors [partnership_projects] + funding progress for the home feed.
class PartnershipProject {
  const PartnershipProject({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.district,
    required this.targetMembers,
    required this.expectedDurationMonths,
    required this.fundingProgress,
    required this.currentMemberCount,
    this.totalUnits,
    this.landPriceEgp,
    this.estimatedBuildCostEgp,
    this.minimumContributionEgp,
    this.status = 'open',
  });

  final String id;
  final String title;
  final String description;
  final String city;
  final String district;
  final int targetMembers;
  final int expectedDurationMonths;
  final double fundingProgress;
  final int currentMemberCount;
  final int? totalUnits;
  final double? landPriceEgp;
  final double? estimatedBuildCostEgp;
  final double? minimumContributionEgp;
  final String status;

  factory PartnershipProject.fromJson(Map<String, dynamic> json) {
    num numeric(Object? value, {num fallback = 0}) => value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? fallback;

    return PartnershipProject(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      targetMembers: numeric(json['targetMembers']).toInt(),
      expectedDurationMonths: numeric(json['expectedDurationMonths']).toInt(),
      fundingProgress: numeric(json['fundingProgress']).toDouble(),
      currentMemberCount: numeric(json['currentMemberCount']).toInt(),
      totalUnits: json['totalUnits'] == null
          ? null
          : numeric(json['totalUnits']).toInt(),
      landPriceEgp: json['landPriceEgp'] == null
          ? null
          : numeric(json['landPriceEgp']).toDouble(),
      estimatedBuildCostEgp: json['estimatedBuildCostEgp'] == null
          ? null
          : numeric(json['estimatedBuildCostEgp']).toDouble(),
      minimumContributionEgp: json['minimumContributionEgp'] == null
          ? null
          : numeric(json['minimumContributionEgp']).toDouble(),
    );
  }

  String membersLabel({bool isArabic = true}) => isArabic
      ? '${_localizeDigits(currentMemberCount.toString(), true)} شريكاً'
      : '$currentMemberCount partners';

  String durationLabel({bool isArabic = true}) => isArabic
      ? '${_localizeDigits(expectedDurationMonths.toString(), true)} شهراً'
      : '$expectedDurationMonths months';

  static String _localizeDigits(String value, bool isArabic) {
    const westernToEastern = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return value.replaceAllMapped(RegExp(r'[0-9]'), (match) =>
        isArabic ? westernToEastern[match[0]]! : match[0]!);
  }
}
