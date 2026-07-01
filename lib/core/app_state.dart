import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/medicine_form_sheet.dart';

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

  ApiService get api => _api;

  // ── Initialization & auth state ──

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get initialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Data loading state ──

  bool _dataLoading = false;
  String? _dataError;

  bool get dataLoading => _dataLoading;
  String? get dataError => _dataError;

  // ── UI-only state ──

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.en;
  UserType _loginType = UserType.patient;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  UserType get loginType => _loginType;
  Locale get locale => Locale(_language.code);
  Localizer get localizer => Localizer(_language);

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
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

  static const _emptyProfile = UserProfile(
    username: '',
    email: '',
    phone: '',
    bio: '',
    avatarPath: 'assets/avatars/avatar_wave.svg',
    useAsset: true,
  );

  UserProfile _profile = _emptyProfile;
  UserType _currentUserType = UserType.patient;

  UserType get currentUserType => _currentUserType;
  UserProfile get pharmacyProfile => _profile;
  UserProfile get patientProfile => _profile;

  // ── Pharmacy data ──

  Map<String, Pharmacy> _pharmacies = {};
  String? _primaryPharmacyId;

  GeoPoint _userLocation = const GeoPoint(lat: 3.876, lng: 11.514);
  bool _locationDetected = false;

  GeoPoint get userLocation => _userLocation;
  bool get locationDetected => _locationDetected;

  String get primaryPharmacyId => _primaryPharmacyId ?? '';
  bool get hasPharmacy => _primaryPharmacyId != null;

  static const _unknownPharmacy = Pharmacy(
    id: '',
    name: '—',
    address: '—',
    lat: 0,
    lng: 0,
    phone: '—',
    accent: Color(0xFF38BDF8),
  );

  Pharmacy get primaryPharmacy =>
      (_primaryPharmacyId != null ? _pharmacies[_primaryPharmacyId] : null) ??
      _unknownPharmacy;

  Pharmacy pharmacyById(String id) => _pharmacies[id] ?? _unknownPharmacy;

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
    return _distanceBetween(_userLocation, pharmacy.point);
  }

  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const radius = 6371;
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

  Future<GeoPoint> detectLocation() async {
    final point = await _locationService.detectUserPosition();
    _userLocation = point;
    _locationDetected = true;
    notifyListeners();
    return point;
  }

  Future<void> updateUserLocation() async {
    try {
      await detectLocation();
      if (_medicines.isNotEmpty) {
        await loadMedicines();
      }
    } catch (_) {}
  }

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

  void _applyUserData(Map<String, dynamic> userData) {
    _profile = UserProfile.fromJson(userData);
    _currentUserType =
        _profile.userType == 'pharmacy' ? UserType.pharmacy : UserType.patient;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      _applyUserData(data['user'] as Map<String, dynamic>);
      await _loadAppData();
      _isLoggedIn = true;
      return data;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register({
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
      final data = await _api.register(
        username: username,
        email: email,
        phone: phone,
        password: password,
        userType: userType == UserType.pharmacy ? 'pharmacy' : 'patient',
      );
      _applyUserData(data['user'] as Map<String, dynamic>);
      await _loadAppData();
      _isLoggedIn = true;
      return data;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _isLoggedIn = false;
    _pharmacies = {};
    _medicines = [];
    _requests = [];
    _primaryPharmacyId = null;
    _profile = _emptyProfile;
    _dataError = null;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final profileData = await _api.getProfile();
    _profile = UserProfile.fromJson(profileData);
    _currentUserType =
        _profile.userType == 'pharmacy' ? UserType.pharmacy : UserType.patient;
    await _loadAppData();
  }

  Future<void> _loadAppData() async {
    _dataLoading = true;
    _dataError = null;
    notifyListeners();

    try {
      await loadPharmacies();
      _resolvePharmacyOwnership();
      await loadMedicines();
      await loadMedicineRequests();
    } on ApiException catch (e) {
      _dataError = e.message;
    } catch (e) {
      _dataError = e.toString();
    } finally {
      _dataLoading = false;
      notifyListeners();
    }
  }

  void _resolvePharmacyOwnership() {
    if (_currentUserType != UserType.pharmacy) return;
    final userId = _api.userId;
    if (userId == null) return;
    _primaryPharmacyId = _pharmacies.values
        .where((p) => p.userId == userId)
        .map((p) => p.id)
        .firstOrNull;
  }

  Future<void> refreshData() async {
    _dataLoading = true;
    _dataError = null;
    notifyListeners();

    try {
      await loadPharmacies();
      _resolvePharmacyOwnership();
      await loadMedicines();
      await loadMedicineRequests();
    } on ApiException catch (e) {
      _dataError = e.message;
    } catch (e) {
      _dataError = e.toString();
    } finally {
      _dataLoading = false;
      notifyListeners();
    }
  }

  // ── Pharmacy creation ──

  Future<void> createPharmacy({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String phone,
  }) async {
    final json = await _api.createPharmacy(
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      phone: phone,
    );
    final pharmacy = Pharmacy.fromJson(json);
    _pharmacies[pharmacy.id] = pharmacy;
    _primaryPharmacyId = pharmacy.id;
    notifyListeners();
  }

  Future<void> updatePharmacy({
    required String name,
    required String address,
    required String phone,
    double? lat,
    double? lng,
  }) async {
    if (_primaryPharmacyId == null) return;
    final data = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final json = await _api.updatePharmacy(int.parse(_primaryPharmacyId!), data);
    final updated = Pharmacy.fromJson(json);
    _pharmacies[updated.id] = updated;
    notifyListeners();
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

  // ── Medicine CRUD (optimistic with rollback) ──

  Future<void> addMedicine(MedicineFormData data) async {
    final tempId = 'tmp-${DateTime.now().millisecondsSinceEpoch}';
    final temp = Medicine(
      id: tempId,
      name: data.name,
      price: data.price,
      description: data.description,
      pharmacyId: primaryPharmacyId,
      distanceKm: 0,
    );
    _medicines.add(temp);
    notifyListeners();

    try {
      final json = await _api.addMedicine(
        name: data.name,
        price: data.price,
        description: data.description,
        imagePath: data.imageFile?.path,
      );
      final pharmacyId = json['pharmacy_id'].toString();
      final distance = _pharmacies.containsKey(pharmacyId)
          ? distanceFromPatient(pharmacyId)
          : 0.0;
      final serverMedicine = Medicine.fromJson(
        json,
        distanceKm: double.parse(distance.toStringAsFixed(1)),
      );
      final index = _medicines.indexWhere((m) => m.id == tempId);
      if (index != -1) _medicines[index] = serverMedicine;
      notifyListeners();
    } catch (_) {
      _medicines.removeWhere((m) => m.id == tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMedicine(Medicine existing, MedicineFormData data) async {
    final index = _medicines.indexWhere((m) => m.id == existing.id);
    if (index == -1) return;

    final previous = _medicines[index];
    _medicines[index] = existing.copyWith(
      name: data.name,
      price: data.price,
      description: data.description,
    );
    notifyListeners();

    try {
      final json = await _api.updateMedicine(
        int.parse(existing.id),
        name: data.name,
        price: data.price,
        description: data.description,
        imagePath: data.imageFile?.path,
      );
      _medicines[index] = Medicine.fromJson(
        json,
        distanceKm: previous.distanceKm,
      );
      notifyListeners();
    } catch (_) {
      _medicines[index] = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final removed = _medicines.removeAt(index);
    notifyListeners();

    try {
      await _api.deleteMedicine(int.parse(id));
    } catch (_) {
      _medicines.insert(index, removed);
      notifyListeners();
      rethrow;
    }
  }

  // ── Profile ──

  Future<void> updateProfile(UserType type, UserProfile profile) async {
    final data = await _api.updateProfile(profile.toJson());
    _profile = UserProfile.fromJson(data);
    notifyListeners();
  }
}
