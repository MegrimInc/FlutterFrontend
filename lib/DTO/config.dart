class Config {
  final String iosMobileMinSupportedVersion;
  final String androidMobileMinSupportedVersion;
  final String iosTabletMinSupportedVersion;
  final String androidTabletMinSupportedVersion;

  final List<String> iosMobileBlockedVersions;
  final List<String> androidMobileBlockedVersions;
  final List<String> iosTabletBlockedVersions;
  final List<String> androidTabletBlockedVersions;

  final String serviceFee;

  Config({
    required this.iosMobileMinSupportedVersion,
    required this.androidMobileMinSupportedVersion,
    required this.iosTabletMinSupportedVersion,
    required this.androidTabletMinSupportedVersion,
    required this.iosMobileBlockedVersions,
    required this.androidMobileBlockedVersions,
    required this.iosTabletBlockedVersions,
    required this.androidTabletBlockedVersions,
    required this.serviceFee,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    List<String> parseBlocked(String? value) {
      return (value ?? '')
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
    }

    return Config(
      iosMobileMinSupportedVersion: json['ios_mobile_min_supported_version'] ?? '',
      androidMobileMinSupportedVersion: json['android_mobile_min_supported_version'] ?? '',
      iosTabletMinSupportedVersion: json['ios_tablet_min_supported_version'] ?? '',
      androidTabletMinSupportedVersion: json['android_tablet_min_supported_version'] ?? '',

      iosMobileBlockedVersions: parseBlocked(json['ios_mobile_blocked_versions']),
      androidMobileBlockedVersions: parseBlocked(json['android_mobile_blocked_versions']),
      iosTabletBlockedVersions: parseBlocked(json['ios_tablet_blocked_versions']),
      androidTabletBlockedVersions: parseBlocked(json['android_tablet_blocked_versions']),

      serviceFee: json['service_fee'] ?? '',
    );
  }
}