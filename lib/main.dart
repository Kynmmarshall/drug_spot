import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'models/user_type.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/pharmacy_dashboard_screen.dart';
import 'screens/pharmacy_setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DrugSpotApp());
}

class DrugSpotApp extends StatefulWidget {
  const DrugSpotApp({super.key});

  @override
  State<DrugSpotApp> createState() => _DrugSpotAppState();
}

class _DrugSpotAppState extends State<DrugSpotApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return AppStateScope(
          notifier: _state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Drug Spot',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _state.themeMode,
            locale: _state.locale,
            supportedLocales: const [Locale('en'), Locale('fr')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _buildHome(),
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_state.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_state.isLoggedIn) {
      if (_state.currentUserType == UserType.pharmacy && !_state.hasPharmacy) {
        return const PharmacySetupScreen();
      }
      return _state.currentUserType == UserType.pharmacy
          ? const PharmacyDashboardScreen()
          : const PatientDashboardScreen();
    }

    return const LoginScreen();
  }
}
