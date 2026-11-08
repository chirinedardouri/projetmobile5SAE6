
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ekrili_karhba/features/users/domain/user.dart';
import 'package:ekrili_karhba/features/users/services/user_service.dart';
import 'package:ekrili_karhba/features/users/ui/login_screen.dart';
import 'package:ekrili_karhba/main.dart';

import 'package:ekrili_karhba/controllers/car_recommendation_controller.dart';
import 'package:ekrili_karhba/views/recommendations/ai_car_recommender_view.dart';

void main() {

  // USER MODULE TESTS

  setUp(() {
    UserService.instance.setCurrentUser(
      User(
        id: 1,
        nom: 'Ben Amor',
        prenom: 'Yassine',
        email: 'admin@ekrili.tn',
        telephone: '20100200',
        motDePasse: 'hash',
        passwordSalt: 'salt',
        role: UserRole.admin,
        statut: UserStatus.actif,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    );
  });

  testWidgets('opens the maintenance dashboard when logged in', (tester) async {
    await tester.pumpWidget(const EkriliKarhbaApp());

    expect(find.text('Maintenance'), findsWidgets);
    expect(find.text('Maintenance urgente'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle maintenance'), findsOneWidget);
  });

  testWidgets('displays login screen when user is not authenticated', (tester) async {
    UserService.instance.setCurrentUser(null);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Ekrili Karhba'), findsOneWidget);
    expect(find.text('Connexion à votre espace'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Pas encore de compte ?'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);

    await tester.tap(find.text("S'inscrire"));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Agence'), findsOneWidget);
  });

  // VEHICLES MODULE TESTS

  testWidgets('AiCarRecommenderView displays input fields and button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CarRecommendationController(),
          ),
        ],
        child: const MaterialApp(
          home: AiCarRecommenderView(),
        ),
      ),
    );

    expect(find.text('AI Smart Car Recommender'), findsOneWidget);
    expect(find.text('Recommander 7 Véhicules'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
