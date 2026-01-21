import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider((ref) => LocationService());

final userLocationProvider = StreamProvider<UserLocation?>((ref) async* {
  final service = ref.watch(locationServiceProvider);
  
  // Initial location
  UserLocation? initial;
  try {
    initial = await service.getCurrentLocation();
  } catch (e) {
    debugPrint('Initial location check failed: $e');
  }
  yield initial;

  // Stream updates - only start if we have permission
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      yield* service.getPositionStream().handleError((e) {
        debugPrint('Location stream error: $e');
        return null; // Return null on stream errors
      }).asyncMap((pos) async {
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
    } else {
      debugPrint('Skipping location stream: No permission granted.');
    }
  } catch (e) {
    debugPrint('Error setting up location stream: $e');
  }
});
