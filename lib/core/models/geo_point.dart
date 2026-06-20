import 'app_language.dart';

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  String formatted(AppLanguage language) {
    final latDir = lat >= 0
        ? (language == AppLanguage.en ? 'N' : 'N')
        : (language == AppLanguage.en ? 'S' : 'S');
    final lngDir = lng >= 0
        ? (language == AppLanguage.en ? 'E' : 'E')
        : (language == AppLanguage.en ? 'W' : 'O');
    return '${lat.abs().toStringAsFixed(3)}°$latDir, ${lng.abs().toStringAsFixed(3)}°$lngDir';
  }
}
