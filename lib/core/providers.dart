import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/data/datasources/event_datasource.dart';
import 'package:tech_marathon_app/data/datasources/schedule_datasource.dart';
import 'package:tech_marathon_app/data/datasources/speaker_datasource.dart';
import 'package:tech_marathon_app/data/datasources/sponsor_datasource.dart';
import 'package:tech_marathon_app/data/datasources/app_settings_datasource.dart';
import 'package:tech_marathon_app/data/repositories/event_repository_impl.dart';
import 'package:tech_marathon_app/data/repositories/schedule_repository_impl.dart';
import 'package:tech_marathon_app/data/repositories/speaker_repository_impl.dart';
import 'package:tech_marathon_app/data/repositories/sponsor_repository_impl.dart';
import 'package:tech_marathon_app/data/repositories/app_settings_repository_impl.dart';
import 'package:tech_marathon_app/domain/repositories/event_repository.dart';
import 'package:tech_marathon_app/domain/repositories/schedule_repository.dart';
import 'package:tech_marathon_app/domain/repositories/speaker_repository.dart';
import 'package:tech_marathon_app/domain/repositories/sponsor_repository.dart';
import 'package:tech_marathon_app/domain/repositories/app_settings_repository.dart';

// --- DATA SOURCES ---
final eventDataSourceProvider = Provider<EventDataSource>((ref) {
  return EventDataSourceImpl();
});

final scheduleDataSourceProvider = Provider<ScheduleDataSource>((ref) {
  return ScheduleDataSourceImpl();
});

final speakerDataSourceProvider = Provider<SpeakerDataSource>((ref) {
  return SpeakerDataSourceImpl();
});

final sponsorDataSourceProvider = Provider<SponsorDataSource>((ref) {
  return SponsorDataSourceImpl();
});

final appSettingsDataSourceProvider = Provider<AppSettingsDataSource>((ref) {
  return AppSettingsDataSourceImpl();
});

// --- REPOSITORIES ---
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dataSource = ref.watch(eventDataSourceProvider);
  return EventRepositoryImpl(dataSource);
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dataSource = ref.watch(scheduleDataSourceProvider);
  return ScheduleRepositoryImpl(dataSource);
});

final speakerRepositoryProvider = Provider<SpeakerRepository>((ref) {
  final dataSource = ref.watch(speakerDataSourceProvider);
  return SpeakerRepositoryImpl(dataSource);
});

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) {
  final dataSource = ref.watch(sponsorDataSourceProvider);
  return SponsorRepositoryImpl(dataSource);
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final dataSource = ref.watch(appSettingsDataSourceProvider);
  return AppSettingsRepositoryImpl(dataSource);
});
