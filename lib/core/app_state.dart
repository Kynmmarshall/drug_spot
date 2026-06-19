import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../models/geo_point.dart';
import '../models/medicine.dart';
import '../models/medicine_request.dart';
import '../models/pharmacy.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';
import '../services/api_service.dart';
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
  AppState({
    ApiService? apiService,
    LocationService? locationService,
  })  : _api = apiService ?? ApiService(),
        _locationService = locationService ?? LocationService();

  final ApiService _api;
  final LocationService _locationService;

  // ── Initialization & auth state ──

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get initialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── UI-only state ──

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.en;
  UserType _loginType = UserType.patient;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  UserType get loginType => _loginType;
  Locale get locale => Locale(_language.code);
  Localizer get localizer => Localizer(_language);

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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

  // ── User & profile data ──

  UserProfile _profile = const UserProfile(
    username: '',
    email: '',
    phone: '',
    bio: '',
    avatarPath: 'assets/avatars/avatar_wave.svg',
    useAsset: true,
  );
  UserType _currentUserType = UserType.patient;

  UserType get currentUserType => _currentUserType;
  UserProfile get pharmacyProfile => _profile;
  UserProfile get patientProfile => _profile;

  // ── Pharmacy data ──

  Map<String, Pharmacy> _pharmacies = {};
  String? _primaryPharmacyId;

  final GeoPoint patientLocation = const GeoPoint(lat: 3.876, lng: 11.514);

  String get primaryPharmacyId => _primaryPharmacyId ?? '';

  Pharmacy get primaryPharmacy => _pharmacies[_primaryPharmacyId]!;

  Pharmacy pharmacyById(String id) => _pharmacies[id]!;

  List<Pharmacy> get pharmacies => _pharmacies.values.toList(growable: false);

  // ── Medicine data ──

  List<Medicine> _medicines = [];

  List<Medicine> get medicines => List.unmodifiable(_medicines);

  List<Medicine> medicinesByPharmacy(String id) =>
      _medicines.where((m) => m.pharmacyId == id).toList();

  // ── Medicine request data ──

  List<MedicineRequest> _requests = [];

  List<MedicineRequest> get medicineRequests => List.unmodifiable(_requests);

  // ── Distance calculation ──

  double distanceFromPatient(String pharmacyId) {
    final pharmacy = _pharmacies[pharmacyId];
    if (pharmacy == null) return 0;
    return _distanceBetween(patientLocation, pharmacy.point);
  }

  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const radius = 6371; // km
    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);
    final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.lat)) *
            math.cos(_degToRad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return radius * c;
  }

  double _degToRad(double value) => value * math.pi / 180;

  Future<GeoPoint> detectLocation() => _locationService.detectUserPosition();

  // ── Initialization ──

  Future<void> init() async {
    await _api.loadToken();
    if (_api.hasToken) {
      try {
        await _loadUserData();
        _isLoggedIn = true;
      } catch (_) {
        await _api.clearToken();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // ── Auth ──

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.login(username, password);
      await _loadUserData();
      _isLoggedIn = true;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.register(
        username: username,
        email: email,
        phone: phone,
        password: password,
        userType: userType == UserType.pharmacy ? 'pharmacy' : 'patient',
      );
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    _isLoggedIn = false;
    _pharmacies = {};
    _medicines = [];
    _requests = [];
    _primaryPharmacyId = null;
    _profile = const UserProfile(
      username: '',
      email: '',
      phone: '',
      bio: '',
      avatarPath: 'assets/avatars/avatar_wave.svg',
      useAsset: true,
    );
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final profileData = await _api.getProfile();
    _profile = UserProfile.fromJson(profileData);
    _currentUserType = _profile.userType == 'pharmacy'
        ? UserType.pharmacy
        : UserType.patient;

    await loadPharmacies();
    await loadMedicines();
    await loadMedicineRequests();

    if (_currentUserType == UserType.pharmacy) {
      final userId = _api.userId;
      _primaryPharmacyId = _pharmacies.values
          .where((p) => p.userId == userId)
          .map((p) => p.id)
          .firstOrNull;
    }
  }

  // ── Data loading ──

  Future<void> loadPharmacies() async {
    final data = await _api.getPharmacies();
    _pharmacies = {
      for (final json in data)
        (json as Map<String, dynamic>)['id'].toString():
            Pharmacy.fromJson(json),
    };
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    final data = await _api.getMedicines();
    _medicines = data.map((json) {
      final map = json as Map<String, dynamic>;
      final pharmacyId = map['pharmacy_id'].toString();
      final distance = _pharmacies.containsKey(pharmacyId)
          ? distanceFromPatient(pharmacyId)
          : 0.0;
      return Medicine.fromJson(map,
          distanceKm: double.parse(distance.toStringAsFixed(1)));
    }).toList();
    notifyListeners();
  }

  Future<void> loadMedicineRequests() async {
    final data = await _api.getMedicineRequests();
    _requests = data
        .map((json) => MedicineRequest.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  // ── Medicine CRUD ──

  Future<void> addMedicine(Medicine medicine) async {
    final json = await _api.addMedicine(medicine.name, medicine.price);
    final pharmacyId = json['pharmacy_id'].toString();
    final distance = _pharmacies.containsKey(pharmacyId)
        ? distanceFromPatient(pharmacyId)
        : 0.0;
    _medicines.add(Medicine.fromJson(json,
        distanceKm: double.parse(distance.toStringAsFixed(1))));
    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _api.updateMedicine(
        int.parse(medicine.id), medicine.name, medicine.price);
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(String id) async {
    await _api.deleteMedicine(int.parse(id));
    _medicines.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ── Profile ──

  Future<void> updateProfile(UserType type, UserProfile profile) async {
    await _api.updateProfile(profile.toJson());
    _profile = profile;
    notifyListeners();
  }
}
