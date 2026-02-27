import 'rustfs_settings.dart';

class TempLink {
  const TempLink({
    required this.link,
    required this.objectName,
    required this.expiresAt,
    required this.settings,
  });

  final String link;
  final String objectName;
  final DateTime expiresAt;
  final RustFsSettings settings;
}
