import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_reserv/controllers/car_recommendation_controller.dart';
import 'package:gestion_reserv/views/recommendations/ai_car_recommender_view.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AiCarRecommenderView displays input fields and button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CarRecommendationController()),
        ],
        child: const MaterialApp(
          home: AiCarRecommenderView(),
        ),
      ),
    );

    // Verify header and fields exist
    expect(find.text('AI Smart Car Recommender'), findsOneWidget);
    expect(find.text('Recommander 7 Véhicules'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
