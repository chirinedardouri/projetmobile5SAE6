import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/car_recommendation.dart';

class GroqAiException implements Exception {
  final String message;
  final int? statusCode;

  GroqAiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class GroqAiService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// Modèle préféré selon les spécifications.
  /// Note: Sur Groq, si un identifiant spécifique n'est pas actif,
  /// vous pouvez également utiliser "llama-3.3-70b-versatile" ou "llama-3.1-8b-instant".
  static const String defaultModel = 'openai/gpt-oss-20b';
  static const String fallbackModel = 'llama-3.3-70b-versatile';

  static const String apiKeyConstant = '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';

  final String? apiKey;
  final String model;

  GroqAiService({
    this.apiKey,
    this.model = defaultModel,
  });

  /// Récupère la clé API depuis le paramètre fourni, la constante directe, ou l'environnement
  String get effectiveApiKey {
    final key = apiKey;
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    if (apiKeyConstant.trim().isNotEmpty) {
      return apiKeyConstant.trim();
    }
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    return envKey.trim();
  }

  /// Appelle l'API Groq pour recommander exactement 7 véhicules selon les 3 mots-clés
  Future<CarRecommendationResponse> fetchRecommendations({
    required String keyword1,
    required String keyword2,
    required String keyword3,
    String? overrideApiKey,
  }) async {
    final key = (overrideApiKey != null && overrideApiKey.trim().isNotEmpty)
        ? overrideApiKey.trim()
        : effectiveApiKey;

    if (key.isEmpty) {
      throw GroqAiException(
        'Clé API Groq manquante. Veuillez configurer votre clé API Groq via '
        '--dart-define=GROQ_API_KEY=votre_cle ou via le bouton Clé API dans l\'écran.',
        statusCode: 401,
      );
    }

    final trimmedK1 = keyword1.trim();
    final trimmedK2 = keyword2.trim();
    final trimmedK3 = keyword3.trim();

    final systemPrompt = '''
Tu es un moteur d'intelligence artificielle expert automobile pour l'application de location "Ekrili Karhba".
Ton rôle est d'analyser trois mots-clés décrivant le voyage d'un client (ex: terrain, type de voyage, exigences) et de recommander EXACTEMENT les 7 modèles de voitures les plus adaptés, classés du plus approprié (#1) au moins approprié (#7).

Règles impératives :
1. Renvoie STRICTEMENT un objet JSON valide, sans texte additionnel, sans markdown backticks (ou bloc ```json valide).
2. L'objet JSON DOIT comporter exactement cette structure :
{
  "intro": "Brève explication (en français) de l'analyse des mots-clés et des besoins déduits pour ce trajet.",
  "recommendations": [
    {
      "brand": "Marque (ex: Toyota)",
      "model": "Modèle (ex: RAV4)",
      "category": "Catégorie (SUV, Berline, Crossover, 4x4, Citadine, etc.)",
      "suitabilityScore": 95,
      "reasons": "Courte explication reliant précisément les caractéristiques du véhicule aux 3 mots-clés du voyage.",
      "advantages": [
        "Premier avantage spécifique au trajet",
        "Deuxième avantage clé"
      ],
      "limitations": [
        "Limite ou mise en garde importante pour ce modèle/trajet"
      ]
    }
  ],
  "generalNote": "Note claire rappelant que cette sélection repose sur l'adéquation technique générale du modèle et ne garantit pas la disponibilité physique immédiate dans la flotte de l'agence locale."
}
3. Le tableau "recommendations" DOIT contenir EXACTEMENT 7 modèles distincts.
4. "suitabilityScore" est un entier compris entre 0 et 100, strictement décroissant ou ordonné du plus au moins approprié.
5. Ne prétends JAMAIS qu'un véhicule est disponible dans la flotte de l'agence de location ; indique toujours qu'il s'agit d'une recommandation de modèle adapté.
6. N'invente pas de tarifs de location ou de statistiques de popularité fictives.
7. Rédige l'ensemble du contenu en français clair, précis et professionnel.
''';

    final userMessage = '''
Mots-clés fournis par le client pour son voyage :
1. "$trimmedK1"
2. "$trimmedK2"
3. "$trimmedK3"

Analyse ces 3 mots-clés et renvoie les 7 modèles de véhicules les plus adaptés au format JSON demandé.
''';

    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
    };

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 40));
    } on SocketException {
      throw GroqAiException('Impossible de contacter l\'API Groq. Vérifiez votre connexion Internet.');
    } on TimeoutException {
      throw GroqAiException('La requête vers l\'API Groq a expiré (timeout). Veuillez réessayer.');
    } catch (e) {
      throw GroqAiException('Erreur de communication réseau : $e');
    }

    if (response.statusCode == 401) {
      throw GroqAiException(
        'Clé API Groq invalide ou non autorisée (401 Unauthorized). Vérifiez votre clé.',
        statusCode: 401,
      );
    } else if (response.statusCode == 429) {
      throw GroqAiException(
        'Limite de requêtes atteinte sur l\'API Groq (429 Rate Limit Exceeded). '
        'Veuillez patienter un instant avant de relancer l\'analyse.',
        statusCode: 429,
      );
    } else if (response.statusCode == 404 || response.statusCode == 400) {
      // Si le modèle spécifié n'existe pas ou n'est pas supporté par le compte, tente un fallback automatique
      if (model != fallbackModel && response.body.contains('model')) {
        return _retryWithFallback(
          keyword1: trimmedK1,
          keyword2: trimmedK2,
          keyword3: trimmedK3,
          apiKey: key,
          originalError: response.body,
        );
      }
      throw GroqAiException(
        'Erreur de requête API Groq (${response.statusCode}) : ${response.body}',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode != 200) {
      throw GroqAiException(
        'Erreur API Groq (${response.statusCode}) : ${response.body}',
        statusCode: response.statusCode,
      );
    }

    return _parseGroqResponse(response.body);
  }

  /// Tente une seconde requête avec le modèle de secours Llama sur Groq
  Future<CarRecommendationResponse> _retryWithFallback({
    required String keyword1,
    required String keyword2,
    required String keyword3,
    required String apiKey,
    required String originalError,
  }) async {
    final fallbackService = GroqAiService(apiKey: apiKey, model: fallbackModel);
    try {
      return await fallbackService.fetchRecommendations(
        keyword1: keyword1,
        keyword2: keyword2,
        keyword3: keyword3,
        overrideApiKey: apiKey,
      );
    } catch (_) {
      throw GroqAiException(
        'Le modèle principal "$model" et le modèle de repli "$fallbackModel" ont échoué. '
        'Détail : $originalError',
      );
    }
  }

  CarRecommendationResponse _parseGroqResponse(String responseBody) {
    try {
      final decodedResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = decodedResponse['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw GroqAiException('Réponse vide reçue de l\'API Groq.');
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw GroqAiException('Aucun contenu textuel renvoyé par le modèle IA.');
      }

      // Nettoie d'éventuels délimiteurs markdown ```json ... ``` si le modèle en a inclus
      String cleanJson = content.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson
            .replaceAll(RegExp(r'^```(json)?\s*', multiLine: true), '')
            .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
            .trim();
      }

      final parsedJson = jsonDecode(cleanJson) as Map<String, dynamic>;
      return CarRecommendationResponse.fromJson(parsedJson);
    } on FormatException catch (e) {
      throw GroqAiException('Format JSON invalide renvoyé par l\'IA : ${e.message}');
    } catch (e) {
      if (e is GroqAiException) rethrow;
      throw GroqAiException('Erreur lors du traitement de la réponse IA : $e');
    }
  }
}
