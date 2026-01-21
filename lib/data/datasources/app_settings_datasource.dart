import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'package:tech_marathon_app/data/models/app_settings.dart';

abstract class AppSettingsDataSource {
  Stream<AppSettings> watchAppSettings();
  Future<AppSettings?> getAppSettings();
  Future<void> updateAppSettings(AppSettings settings);
}

class AppSettingsDataSourceImpl implements AppSettingsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<AppSettings> _hiveBox = Hive.box<AppSettings>('appSettingsBox');
  static const String _settingsDocId = 'global_settings'; // or 'default'

  @override
  Stream<AppSettings> watchAppSettings() {
    final firestoreStream = _firestore
        .collection('app_settings')
        .doc(_settingsDocId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Return default if not found
        return AppSettings(
          primaryColor: '#FFFFFF',
          secondaryColor: '#000000',
          logoUrl: '',
          appIconUrl: '',
          brandingJson: {},
        );
      }
      final settings = AppSettings.fromMap(snapshot.data()!);
      _hiveBox.put(_settingsDocId, settings);
      return settings;
    });

    final cacheStream = Stream<AppSettings>.periodic(Duration(seconds: 1), (_) {
      final cached = _hiveBox.get(_settingsDocId);
      return cached ??
          AppSettings(
            primaryColor: '#FFFFFF',
            secondaryColor: '#000000',
            logoUrl: '',
            appIconUrl: '',
            brandingJson: {},
          );
    }).take(1);

    return cacheStream.concatWith([firestoreStream]);
  }

  @override
  Future<AppSettings?> getAppSettings() async {
    final cached = _hiveBox.get(_settingsDocId);
    if (cached != null) return cached;
    final doc = await _firestore.collection('app_settings').doc(_settingsDocId).get();
    if (!doc.exists) return null;
    final settings = AppSettings.fromMap(doc.data()!);
    _hiveBox.put(_settingsDocId, settings);
    return settings;
  }

  @override
  Future<void> updateAppSettings(AppSettings settings) async {
    await _firestore
        .collection('app_settings')
        .doc(_settingsDocId)
        .set(settings.toMap());
    _hiveBox.put(_settingsDocId, settings);
  }
}
