import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationProblem implements Exception {
  LocationProblem(this.message, {this.serviceOff = false, this.canOpenSettings = false});

  final String message;
  final bool serviceOff;
  final bool canOpenSettings;

  @override
  String toString() => message;
}

/// Kuryerning joriy joylashuvi (har ~15 metrda yangilanadi).
final courierPositionProvider = StreamProvider.autoDispose<LatLng>((ref) async* {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw LocationProblem("GPS o'chiq. Joylashuvni yoqing.", serviceOff: true);
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied) {
    throw LocationProblem('Joylashuvga ruxsat berilmadi.');
  }
  if (perm == LocationPermission.deniedForever) {
    throw LocationProblem("Joylashuvga ruxsatni sozlamalardan bering.", canOpenSettings: true);
  }

  try {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    yield LatLng(p.latitude, p.longitude);
  } catch (_) {
    // Birinchi aniqlash kechiksa, oqim o'zi yuboradi
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    ),
  ).map((p) => LatLng(p.latitude, p.longitude));
});
