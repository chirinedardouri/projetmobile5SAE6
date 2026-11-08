import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_reserv/controllers/car_recommendation_controller.dart';
import 'package:gestion_reserv/models/car_recommendation.dart';

void main() {
  group('Car Recommendation Model Tests', () {
    test('Correctly parses valid Groq JSON with 7 recommendations', () {
      final sampleJson = {
        "intro": "Pour un trajet familial en montagne sur des chemins rocheux, nous privilégions des SUV et 4x4 robustes.",
        "recommendations": [
          {
            "brand": "Toyota",
            "model": "RAV4",
            "category": "SUV",
            "suitabilityScore": 96,
            "reasons": "Transmission intégrale AWD efficace et excellente fiabilité sur terrains accidentés.",
            "advantages": ["Grand coffre pour les bagages familiaux", "Bonne garde au sol"],
            "limitations": ["Suspensions fermes sur grosses pierres"]
          },
          {
            "brand": "Subaru",
            "model": "Outback",
            "category": "Crossover / Break",
            "suitabilityScore": 94,
            "reasons": "Transmission intégrale symétrique de référence et confort routier élevé.",
            "advantages": ["Excellente motricité permanente", "Habitacle très spacieux"],
            "limitations": ["Gabarit plus long pour manœuvrer sur pistes étroites"]
          },
          {
            "brand": "Jeep",
            "model": "Wrangler",
            "category": "4x4 Pur",
            "suitabilityScore": 92,
            "reasons": "Capacités de franchissement incomparables pour les passages très rocheux.",
            "advantages": ["Boîte de transfert avec réducteur", "Garde au sol maximale"],
            "limitations": ["Confort spartiate pour les longs trajets en famille"]
          },
          {
            "brand": "Jeep",
            "model": "Grand Cherokee",
            "category": "Grand SUV",
            "suitabilityScore": 89,
            "reasons": "Allie puissance, sécurité et confort familial sur chemins escarpés.",
            "advantages": ["Confort premium", "Habitabilité exceptionnelle"],
            "limitations": ["Consommation de carburant plus élevée"]
          },
          {
            "brand": "Dacia",
            "model": "Duster 4x4",
            "category": "SUV Compact",
            "suitabilityScore": 87,
            "reasons": "Léger, économique et surprenant d'efficacité sur pistes dégradées.",
            "advantages": ["Tarif de location attractif", "Robustesse éprouvée"],
            "limitations": ["Insonorisation moyenne sur autoroute"]
          },
          {
            "brand": "Subaru",
            "model": "Forester",
            "category": "SUV",
            "suitabilityScore": 85,
            "reasons": "Visibilité panoramique exceptionnelle et transmission intégrale permanente sécurisante.",
            "advantages": ["Sécurité active poussée", "Espace généreux aux places arrière"],
            "limitations": ["Moteur linéaire manquant de reprise à pleine charge"]
          },
          {
            "brand": "Suzuki",
            "model": "Jimny",
            "category": "Mini 4x4",
            "suitabilityScore": 78,
            "reasons": "Ultra agile sur rochers mais espace limité pour les bagages.",
            "advantages": ["Rayon de braquage court", "Franchisseur hors pair"],
            "limitations": ["Coffre et places arrière très exigus pour une famille"]
          }
        ],
        "generalNote": "Recommandation basée sur l'adéquation technique constructeur. La disponibilité effective dépend de la flotte de l'agence."
      };

      final response = CarRecommendationResponse.fromJson(sampleJson);

      expect(response.recommendations.length, 7);
      expect(response.recommendations[0].fullName, 'Toyota RAV4');
      expect(response.recommendations[0].suitabilityScore, 96);
      expect(response.recommendations[0].category, 'SUV');
      expect(response.recommendations[0].advantages.length, 2);
      expect(response.recommendations[0].limitations.length, 1);
      expect(response.generalNote.contains('flotte de l\'agence'), isTrue);
    });

    test('Robust handling of missing or malformed fields', () {
      final json = {
        "intro": null,
        "recommendations": [
          {
            "brand": "Toyota",
            "model": null,
            "category": null,
            "suitabilityScore": "95%",
            "reason": "Test reason",
            "advantages": "Single string advantage",
            "limitations": null
          }
        ]
      };

      final response = CarRecommendationResponse.fromJson(json);
      expect(response.recommendations.length, 1);
      final item = response.recommendations.first;
      expect(item.brand, 'Toyota');
      expect(item.model, 'Modèle non spécifié');
      expect(item.suitabilityScore, 95);
      expect(item.advantages, ['Single string advantage']);
      expect(item.limitations, isEmpty);
    });
  });

  group('Car Recommendation Controller Tests', () {
    test('Validates empty keywords correctly', () {
      final ctrl = CarRecommendationController();

      expect(
        ctrl.validateKeywords('', 'rocheux', 'famille'),
        contains('Veuillez renseigner les trois mots-clés'),
      );

      expect(
        ctrl.validateKeywords('a', 'rocheux', 'famille'),
        contains('au moins 2 caractères'),
      );

      expect(
        ctrl.validateKeywords('test', 'test', 'test'),
        contains('3 mots-clés distincts'),
      );

      expect(
        ctrl.validateKeywords('montagne', 'rocheux', 'famille'),
        isNull,
      );
    });
  });
}
