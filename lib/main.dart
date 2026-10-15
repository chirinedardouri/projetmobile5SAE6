import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'controllers/car_recommendation_controller.dart';
import 'controllers/reservation_controller.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReservationController()),
        ChangeNotifierProvider(create: (_) => CarRecommendationController()),
        // les autres membres ajoutent leurs controllers ici
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ekrili Karhba',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        // Routes nommées
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
      );
}