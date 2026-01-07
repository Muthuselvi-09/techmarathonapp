import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../models/user_location.dart';

class LocationService {
  Future<UserLocation?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          city: place.locality ?? '',
          area: place.subLocality ?? place.name ?? '',
        );
      }
      
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'Unknown',
        area: 'Unknown',
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    );
  }
}
