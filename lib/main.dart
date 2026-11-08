import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';

import 'features/users/services/user_service.dart';
import 'features/users/ui/login_screen.dart';

import 'screens/main_navigation_screen.dart';
import 'routes/app_routes.dart';

import 'controllers/reservation_controller.dart';
import 'controllers/car_recommendation_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar configuration
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize French date formatting
  await initializeDateFormatting('fr_FR');

  // Initialize user authentication
  await UserService.instance.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ReservationController(),
        ),
        ChangeNotifierProvider(
          create: (_) => CarRecommendationController(),
        ),
      ],
      child: const EkriliKarhbaApp(),
    ),
  );
}

class EkriliKarhbaApp extends StatelessWidget {
  const EkriliKarhbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ekrili Karhba',
      debugShowCheckedModeBanner: false,

      // Keep your existing application theme
      theme: AppTheme.lightTheme,

      // French localization
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routes nommées du module Réservations (pushNamed)
      routes: AppRoutes.routes,

      // Preserve your authentication flow
      home: UserService.instance.isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}