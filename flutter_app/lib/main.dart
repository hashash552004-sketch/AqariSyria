import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    return true;
  };
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final firebaseReady = await _initializeFirebase();
  if (firebaseReady) {
    await NotificationService().init();
  }
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();
  runApp(BaitAlOmrApp(firebaseReady: firebaseReady, themeProvider: themeProvider));
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

class BaitAlOmrApp extends StatelessWidget {
  const BaitAlOmrApp({super.key, required this.firebaseReady, required this.themeProvider});

  final bool firebaseReady;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'عقار اونلاين',
        home: FirebaseConfigScreen(),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, tp, _) => MaterialApp(
          title: 'عقار اونلاين',
          debugShowCheckedModeBanner: false,
          navigatorKey: NotificationService.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: tp.locale,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class FirebaseConfigScreen extends StatelessWidget {
  const FirebaseConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1677FF), Color(0xFF4DA3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'تعذر الاتصال',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تأكد من اتصال الإنترنت وأعد تشغيل التطبيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
