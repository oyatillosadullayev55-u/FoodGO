import 'package:latlong2/latlong.dart';

/// Taxminiy hisob: to'g'ri chiziq x 1.3 (ko'chalar egriligi), o'rtacha tezlik 22 km/soat.
/// Aniq yo'l va tirbandlikni hisobga olmaydi.
class RouteEstimate {
  const RouteEstimate(this.meters, this.minutes);

  final double meters;
  final int minutes;

  static const _roadFactor = 1.3;
  static const _speedKmh = 22.0;

  factory RouteEstimate.between(LatLng a, LatLng b) {
    final straight = const Distance().as(LengthUnit.Meter, a, b);
    final road = straight * _roadFactor;
    final mins = (road / 1000 / _speedKmh * 60).ceil();
    return RouteEstimate(road, mins < 1 ? 1 : mins);
  }

  RouteEstimate operator +(RouteEstimate o) =>
      RouteEstimate(meters + o.meters, minutes + o.minutes);

  String get distanceText =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  String get timeText => minutes >= 60 ? '${minutes ~/ 60} soat ${minutes % 60} daq' : '$minutes daq';
}
