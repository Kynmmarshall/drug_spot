import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../models/geo_point.dart';
import '../models/medicine.dart';
import '../models/medicine_request.dart';
import '../models/pharmacy.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';
import '../services/auth_service.dart';
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

  // ─── Auth state ──────────────────────────────────────────────────────────
  AuthUser? _authUser;
  bool _authLoading = false;

  AuthUser? get authUser => _authUser;
  bool get isLoggedIn => _authUser != null;
  bool get authLoading => _authLoading;

  Future<AuthResult> login(String username, String password) async {
    _authLoading = true;
    notifyListeners();
    final result = await AuthService.instance.login(
      username: username,
      password: password,
    );
    if (result.success) {
      _authUser = result.user;
      // Sync loginType with the user_type returned by server
      if (_authUser?.userType == 'pharmacy') {
        _loginType = UserType.pharmacy;
      } else {
        _loginType = UserType.patient;
      }
    }
    _authLoading = false;
    notifyListeners();
    return result;
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    _authLoading = true;
    notifyListeners();
    final result = await AuthService.instance.register(
      username: username,
      email: email,
      phone: phone,
      password: password,
      userType: userType,
    );
    if (result.success) {
      _authUser = result.user;
      _loginType =
          result.user?.userType == 'pharmacy' ? UserType.pharmacy : UserType.patient;
    }
    _authLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _authLoading = true;
    notifyListeners();
    await AuthService.instance.logout();
    _authUser = null;
    _authLoading = false;
    notifyListeners();
  }

  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    String? bio,
  }) async {
    final result = await AuthService.instance.updateProfile(
      email: email,
      phone: phone,
      bio: bio,
    );
    if (result.success) {
      _authUser = result.user;
      notifyListeners();
    }
    return result;
  }

  // Restore auth user from local storage on app start
  Future<void> restoreSession() async {
    _authUser = await AuthService.instance.currentUser;
    if (_authUser != null) {
      _loginType =
          _authUser!.userType == 'pharmacy' ? UserType.pharmacy : UserType.patient;
    }
    notifyListeners();
  }
  // ─────────────────────────────────────────────────────────────────────────

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

  late final List<MedicineRequest> _requests = [
    const MedicineRequest(
      id: 'req-001',
      username: 'Aline Djoum',
      contact: '+237 699 222 123',
      medicineName: 'Ventex 10 mg',
      avatarPath: 'assets/avatars/avatar_coral.svg',
      useAsset: true,
    ),
    const MedicineRequest(
      id: 'req-002',
      username: 'Maurice Ekome',
      contact: '+237 676 004 555',
      medicineName: 'Clarion Insulin',
      avatarPath: 'assets/avatars/avatar_sunrise.svg',
      useAsset: true,
    ),
    const MedicineRequest(
      id: 'req-003',
      username: 'Sophie Ambassa',
      contact: '+237 670 112 098',
      medicineName: 'Saflex Cough Relief',
      avatarPath: 'assets/avatars/avatar_wave.svg',
      useAsset: true,
    ),
    const MedicineRequest(
      id: 'req-004',
      username: 'Daryl Mboa',
      contact: '+237 658 889 400',
      medicineName: 'Lumexa Eye Drops',
      avatarPath:
          'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=300&q=80',
    ),
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

  List<MedicineRequest> get medicineRequests => List.unmodifiable(_requests);

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
