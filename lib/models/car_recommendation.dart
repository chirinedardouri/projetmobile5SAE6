class CarRecommendationItem {
  final String brand;
  final String model;
  final String category;
  final int suitabilityScore;
  final String reasons;
  final List<String> advantages;
  final List<String> limitations;

  CarRecommendationItem({
    required this.brand,
    required this.model,
    required this.category,
    required this.suitabilityScore,
    required this.reasons,
    required this.advantages,
    required this.limitations,
  });

  String get fullName => '$brand $model';

  factory CarRecommendationItem.fromJson(Map<String, dynamic> json) {
    return CarRecommendationItem(
      brand: (json['brand'] ?? 'Inconnu').toString(),
      model: (json['model'] ?? 'Modèle non spécifié').toString(),
      category: (json['category'] ?? 'Catégorie générale').toString(),
      suitabilityScore: _parseScore(json['suitabilityScore']),
      reasons: (json['reasons'] ?? json['reason'] ?? '').toString(),
      advantages: _parseList(json['advantages']),
      limitations: _parseList(json['limitations']),
    );
  }

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'category': category,
        'suitabilityScore': suitabilityScore,
        'reasons': reasons,
        'advantages': advantages,
        'limitations': limitations,
      };

  static int _parseScore(dynamic val) {
    if (val is num) {
      return val.round().clamp(0, 100);
    }
    if (val is String) {
      final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) return parsed.clamp(0, 100);
    }
    return 80;
  }

  static List<String> _parseList(dynamic val) {
    if (val is List) {
      return val
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (val is String && val.trim().isNotEmpty) {
      return [val.trim()];
    }
    return const [];
  }
}

class CarRecommendationResponse {
  final String intro;
  final List<CarRecommendationItem> recommendations;
  final String generalNote;

  CarRecommendationResponse({
    required this.intro,
    required this.recommendations,
    required this.generalNote,
  });

  factory CarRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['recommendations'] as List? ?? [])
        .map((e) => CarRecommendationItem.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();

    return CarRecommendationResponse(
      intro: (json['intro'] ?? '').toString(),
      recommendations: list,
      generalNote: (json['generalNote'] ??
              'Ces recommandations reposent sur les caractéristiques constructeur et la pertinence générale. La disponibilité effective dépend de la flotte locale.')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'intro': intro,
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'generalNote': generalNote,
      };
}
