import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../models/geo_point.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';
import '../services/location_service.dart';
import 'localizer.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope is missing in the widget tree');
    return scope!.notifier!;
  }
}

class AppState extends ChangeNotifier {
  AppState({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.en;
  UserType _loginType = UserType.patient;

  final String primaryPharmacyId = 'pharmacy-aurora';
  final GeoPoint patientLocation = const GeoPoint(lat: 3.876, lng: 11.514);

  late final Map<String, Pharmacy> _pharmacies = {
    'pharmacy-aurora': const Pharmacy(
      id: 'pharmacy-aurora',
      name: 'Aurora Care Pharmacy',
      address: '12 Unity Ave, Bonapriso',
      lat: 4.043,
      lng: 9.706,
      phone: '+237 699 123 456',
      accent: Color(0xFF38BDF8),
    ),
    'pharmacy-horizon': const Pharmacy(
      id: 'pharmacy-horizon',
      name: 'Horizon Pharma',
      address: '45 Palm Ring Rd, Yaoundé',
      lat: 3.861,
      lng: 11.517,
      phone: '+237 653 440 201',
      accent: Color(0xFFFB7185),
    ),
    'pharmacy-lotus': const Pharmacy(
      id: 'pharmacy-lotus',
      name: 'Lotus Med Hub',
      address: 'Rue 532, Bastos',
      lat: 3.884,
      lng: 11.513,
      phone: '+237 677 332 871',
      accent: Color(0xFF34D399),
    ),
    'pharmacy-coastline': const Pharmacy(
      id: 'pharmacy-coastline',
      name: 'Coastline Relief',
      address: '257 Marine Dr, Kribi',
      lat: 2.939,
      lng: 9.910,
      phone: '+237 620 112 900',
      accent: Color(0xFFFBBF24),
    ),
  };

  late final List<Medicine> _medicines = [
    _seedMedicine('med-ventex', 'Ventex 10 mg', 1850, 'pharmacy-aurora'),
    _seedMedicine('med-neurozil', 'Neurozil Forte', 6400, 'pharmacy-horizon'),
    _seedMedicine('med-saflex', 'Saflex Cough Relief', 2300, 'pharmacy-aurora'),
    _seedMedicine('med-clarion', 'Clarion Insulin', 11800, 'pharmacy-lotus'),
    _seedMedicine('med-mavyo', 'Mavyo Kids Syrup', 3200, 'pharmacy-coastline'),
    _seedMedicine('med-lumexa', 'Lumexa Eye Drops', 4100, 'pharmacy-horizon'),
  ];

  UserProfile _pharmacyProfile = const UserProfile(
    username: 'Aurora Care',
    email: 'hello@auroracare.cm',
    phone: '+237 699 123 456',
    bio: 'Precision-led pharmacy with coastal delivery.',
    avatarPath: 'assets/avatars/avatar_wave.svg',
    useAsset: true,
  );

  UserProfile _patientProfile = const UserProfile(
    username: 'Patient Lumi',
    email: 'patient@drugspot.app',
    phone: '+237 680 777 001',
    bio: 'Actively tracking stock for chronic care.',
    avatarPath: 'assets/avatars/avatar_mint.svg',
    useAsset: true,
  );

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  UserType get loginType => _loginType;
  Locale get locale => Locale(_language.code);
  Localizer get localizer => Localizer(_language);

  Pharmacy pharmacyById(String id) => _pharmacies[id]!;

  List<Pharmacy> get pharmacies => _pharmacies.values.toList(growable: false);

  List<Medicine> get medicines => List.unmodifiable(_medicines);

  Pharmacy get primaryPharmacy => pharmacyById(primaryPharmacyId);

  UserProfile get pharmacyProfile => _pharmacyProfile;

  UserProfile get patientProfile => _patientProfile;

  List<Medicine> medicinesByPharmacy(String id) =>
      _medicines.where((medicine) => medicine.pharmacyId == id).toList();

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void selectLoginType(UserType type) {
    _loginType = type;
    notifyListeners();
  }

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);
    notifyListeners();
  }

  void updateMedicine(Medicine medicine) {
    final index = _medicines.indexWhere((item) => item.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
      notifyListeners();
    }
  }

  void deleteMedicine(String id) {
    _medicines.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateProfile(UserType type, UserProfile profile) {
    if (type == UserType.pharmacy) {
      _pharmacyProfile = profile;
    } else {
      _patientProfile = profile;
    }
    notifyListeners();
  }

  Future<GeoPoint> detectLocation() => _locationService.detectUserPosition();

  double distanceFromPatient(String pharmacyId) {
    final pharmacy = pharmacyById(pharmacyId);
    return _distanceBetween(patientLocation, pharmacy.point);
  }

  Medicine _seedMedicine(
    String id,
    String name,
    double price,
    String pharmacyId,
  ) {
    final distance = distanceFromPatient(pharmacyId);
    return Medicine(
      id: id,
      name: name,
      price: price,
      pharmacyId: pharmacyId,
      distanceKm: double.parse(distance.toStringAsFixed(1)),
    );
  }

  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const radius = 6371; // km
    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);
    final aa =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.lat)) *
            math.cos(_degToRad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return radius * c;
  }

  double _degToRad(double value) => value * math.pi / 180;
}
