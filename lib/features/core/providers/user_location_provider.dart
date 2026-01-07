import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider((ref) => LocationService());

final userLocationProvider = StreamProvider<UserLocation?>((ref) async* {
  final service = ref.watch(locationServiceProvider);
  
  // Initial location
  final initial = await service.getCurrentLocation();
  yield initial;

  // Stream updates
  yield* service.getPositionStream().asyncMap((pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return UserLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          city: place.locality ?? '',
          area: place.subLocality ?? place.name ?? '',
        );
      }
      return UserLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        city: 'Unknown',
        area: 'Unknown',
      );
    } catch (e) {
      return null;
    }
  });
});
