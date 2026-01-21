import 'package:tech_marathon_app/data/models/app_settings.dart';

abstract class AppSettingsRepository {
  /// Watch app settings as a stream (real‑time updates).
  Stream<AppSettings> watchAppSettings();

  /// Get the current settings (cached or from Firestore).
  Future<AppSettings?> getAppSettings();

  /// Update the settings (writes to Firestore and local cache).
  Future<void> updateAppSettings(AppSettings settings);
}
