import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import '/providers/app_provider.dart';
import '/providers/signup_provider.dart';
import '/providers/login_provider.dart';
import '/providers/locale_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '/firebaseOptions.dart';
import '/providers/authProvider.dart';
import '/screens/splash.dart';
import '/utils/navigator_key.dart';
import 'dart:io' show HttpOverrides, HttpClient, SecurityContext, X509Certificate;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import '/config/stripe_config.dart';

class _AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    HttpOverrides.global = _AppHttpOverrides();
  }
  try {
    Stripe.publishableKey = StripeConfig.publishableKey;
    if (!kIsWeb) {
      await Stripe.instance.applySettings();
    }
  } catch (e) {
    debugPrint('Stripe initialization error: $e');
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Uživaj',
      locale: locale,
      supportedLocales: const [Locale('hr'), Locale('en')],
      localizationsDelegates: const [
        CountryLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
