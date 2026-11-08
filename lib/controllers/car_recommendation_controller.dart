import 'package:flutter/foundation.dart';
import '../models/car_recommendation.dart';
import '../services/groq_ai_service.dart';

class CarRecommendationController extends ChangeNotifier {
  final GroqAiService _aiService;

  CarRecommendationResponse? _response;
  bool _isLoading = false;
  String? _errorMessage;
  String _customApiKey = '';
  List<String> _lastKeywords = [];

  CarRecommendationController({GroqAiService? aiService})
      : _aiService = aiService ?? GroqAiService();

  // Getters
  CarRecommendationResponse? get response => _response;
  List<CarRecommendationItem> get recommendations =>
      _response?.recommendations ?? [];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _response != null && recommendations.isNotEmpty;
  String get customApiKey => _customApiKey;
  List<String> get lastKeywords => List.unmodifiable(_lastKeywords);

  /// Vérifie si une clé est configurée soit via l'environnement soit via l'interface
  bool get hasApiKey =>
      _customApiKey.trim().isNotEmpty ||
      _aiService.effectiveApiKey.trim().isNotEmpty;

  /// Permet à l'utilisateur de saisir ou modifier sa clé API Groq
  void setApiKey(String key) {
    _customApiKey = key.trim();
    notifyListeners();
  }

  /// Validation des trois mots-clés selon les contraintes métier
  String? validateKeywords(String k1, String k2, String k3) {
    final t1 = k1.trim();
    final t2 = k2.trim();
    final t3 = k3.trim();

    if (t1.isEmpty || t2.isEmpty || t3.isEmpty) {
      return 'Veuillez renseigner les trois mots-clés du voyage (ex: Terrain, Type, Exigence).';
    }

    if (t1.length < 2 || t2.length < 2 || t3.length < 2) {
      return 'Chaque mot-clé doit contenir au moins 2 caractères pour une analyse pertinente.';
    }

    if (t1.toLowerCase() == t2.toLowerCase() &&
        t2.toLowerCase() == t3.toLowerCase()) {
      return 'Veuillez saisir 3 mots-clés distincts pour affiner la recommandation.';
    }

    return null;
  }

  /// Exécute la recommandation IA
  Future<bool> searchRecommendations({
    required String keyword1,
    required String keyword2,
    required String keyword3,
  }) async {
    final validationError = validateKeywords(keyword1, keyword2, keyword3);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastKeywords = [keyword1.trim(), keyword2.trim(), keyword3.trim()];
    notifyListeners();

    try {
      final result = await _aiService.fetchRecommendations(
        keyword1: keyword1,
        keyword2: keyword2,
        keyword3: keyword3,
        overrideApiKey: _customApiKey.isNotEmpty ? _customApiKey : null,
      );

      _response = result;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on GroqAiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue : $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Relance la dernière recherche effectuée
  Future<bool> retry() async {
    if (_lastKeywords.length == 3) {
      return searchRecommendations(
        keyword1: _lastKeywords[0],
        keyword2: _lastKeywords[1],
        keyword3: _lastKeywords[2],
      );
    }
    return false;
  }

  /// Réinitialise les résultats et les erreurs
  void clear() {
    _response = null;
    _errorMessage = null;
    _isLoading = false;
    _lastKeywords = [];
    notifyListeners();
  }
}
