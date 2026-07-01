import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'models/user_type.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/pharmacy_dashboard_screen.dart';
import 'services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const DrugSpotApp());
}

class DrugSpotApp extends StatefulWidget {
  const DrugSpotApp({super.key});

  @override
  State<DrugSpotApp> createState() => _DrugSpotAppState();
}

class _DrugSpotAppState extends State<DrugSpotApp> {
  final AppState _state = AppState();
  PushNotificationService? _pushService;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _state.init();
  }

  void _onStateChanged() {
    if (_state.isLoggedIn && _pushService == null) {
      _pushService = PushNotificationService(_state.api);
      _pushService!.init();
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _pushService?.dispose();
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
            builder: (context, child) {
              final isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      isDark
                          ? 'assets/background/dark.png'
                          : 'assets/background/light.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: child!,
              );
            },
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
      return _state.currentUserType == UserType.pharmacy
          ? const PharmacyDashboardScreen()
          : const PatientDashboardScreen();
    }

    return const LoginScreen();
  }
}
