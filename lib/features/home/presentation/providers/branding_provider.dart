import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event_models.dart';
import '../../../../features/admin/data/admin_repository.dart';

final brandingProvider = StreamProvider<BrandingInfo>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchBranding();
});
