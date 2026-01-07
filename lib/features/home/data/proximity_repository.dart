import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/geo_service.dart';
import '../../core/models/user_location.dart';
import '../../core/providers/user_location_provider.dart';

final proximityRepositoryProvider = Provider((ref) => ProximityRepository(FirebaseFirestore.instance));

class ProximityRepository {
  final FirebaseFirestore _firestore;

  ProximityRepository(this._firestore);

  Stream<List<ProximityResult>> getNearby(String collection, UserLocation userLoc, {double radiusKm = 50.0}) {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      final results = <ProximityResult>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];
        if (location != null && location is Map) {
          final lat = (location['lat'] ?? 0.0).toDouble();
          final lng = (location['lng'] ?? 0.0).toDouble();
          
          final distance = GeoService.calculateDistance(
            userLoc.latitude, 
            userLoc.longitude, 
            lat, 
            lng
          );

          if (distance <= radiusKm) {
            results.add(ProximityResult(
              id: doc.id,
              data: data,
              distance: distance,
            ));
          }
        }
      }
      // Sort by distance
      results.sort((a, b) => a.distance.compareTo(b.distance));
      return results;
    });
  }
}

class ProximityResult {
  final String id;
  final Map<String, dynamic> data;
  final double distance;

  ProximityResult({
    required this.id,
    required this.data,
    required this.distance,
  });
}

final nearbyEventsProvider = StreamProvider<List<ProximityResult>>((ref) {
  final userLoc = ref.watch(userLocationProvider).valueOrNull;
  if (userLoc == null) return Stream.value([]);
  
  return ref.watch(proximityRepositoryProvider).getNearby('events', userLoc);
});

final nearbySponsorsProvider = StreamProvider<List<ProximityResult>>((ref) {
  final userLoc = ref.watch(userLocationProvider).valueOrNull;
  if (userLoc == null) return Stream.value([]);
  
  return ref.watch(proximityRepositoryProvider).getNearby('sponsors', userLoc);
});
