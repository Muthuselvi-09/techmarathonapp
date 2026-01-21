import 'package:tech_marathon_app/data/datasources/app_settings_datasource.dart';
import 'package:tech_marathon_app/data/models/app_settings.dart';
import 'package:tech_marathon_app/domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final AppSettingsDataSource _dataSource;

  AppSettingsRepositoryImpl(this._dataSource);

  @override
  Stream<AppSettings> watchAppSettings() => _dataSource.watchAppSettings();

  @override
  Future<AppSettings?> getAppSettings() => _dataSource.getAppSettings();

  @override
  Future<void> updateAppSettings(AppSettings settings) => _dataSource.updateAppSettings(settings);
}
