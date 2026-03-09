import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/services/crashlytics_service.dart';
import 'theme.dart';
import 'nav.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initializeFirebase();

  // Run the app with error handling
  runApp(const MyApp());
}

/// Initialize Firebase and Crashlytics
Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Initialize Crashlytics service
    final crashlytics = CrashlyticsService();
    await crashlytics.initialize();
    
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      
      // Also print to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(errorDetails);
      }
    };
    
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Log app version
    await crashlytics.setAppVersion('1.0.0', '1');
    
    if (kDebugMode) {
      print('✅ Firebase and Crashlytics initialized successfully');
    }
  } catch (e) {
    // If Firebase fails to initialize, log it but continue app startup
    if (kDebugMode) {
      print('⚠️ Firebase initialization failed: $e');
      print('   App will continue without crash reporting');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
      ],
      child: MaterialApp.router(
        title: 'Total Athlete',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
