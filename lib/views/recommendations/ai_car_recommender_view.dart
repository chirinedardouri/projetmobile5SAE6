import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/car_recommendation_controller.dart';
import '../../models/car_recommendation.dart';
import '../../routes/app_routes.dart';

class AiCarRecommenderView extends StatefulWidget {
  const AiCarRecommenderView({super.key});

  @override
  State<AiCarRecommenderView> createState() => _AiCarRecommenderViewState();
}

class _AiCarRecommenderViewState extends State<AiCarRecommenderView> {
  final _k1Controller = TextEditingController(text: 'montagne');
  final _k2Controller = TextEditingController(text: 'rocheux');
  final _k3Controller = TextEditingController(text: 'famille');

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _k1Controller.dispose();
    _k2Controller.dispose();
    _k3Controller.dispose();
    super.dispose();
  }

  void _applyPreset(String k1, String k2, String k3) {
    setState(() {
      _k1Controller.text = k1;
      _k2Controller.text = k2;
      _k3Controller.text = k3;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ctrl = context.read<CarRecommendationController>();
    await ctrl.searchRecommendations(
      keyword1: _k1Controller.text,
      keyword2: _k2Controller.text,
      keyword3: _k3Controller.text,
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final ctrl = context.read<CarRecommendationController>();
    final keyController = TextEditingController(text: ctrl.customApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.indigo),
            SizedBox(width: 10),
            Text('Clé API Groq'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre clé API Groq pour tester le conseiller IA dans ce prototype.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Clé API (ex: gsk_...)',
                hintText: 'gsk_...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En production, la clé ne doit pas être stockée dans l\'application cliente mais gérée via un serveur backend proxy sécurisé.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ctrl.setApiKey(keyController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clé API Groq mise à jour !')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CarRecommendationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conseiller IA Véhicules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ctrl.hasApiKey ? Icons.key : Icons.key_off,
              color: ctrl.hasApiKey ? Colors.amberAccent : Colors.white70,
            ),
            tooltip: 'Configurer la clé API Groq',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildInputSection(ctrl),
            const SizedBox(height: 16),
            if (ctrl.isLoading) _buildLoadingSection(),
            if (ctrl.errorMessage != null && !ctrl.isLoading)
              _buildErrorSection(ctrl),
            if (ctrl.hasResults && !ctrl.isLoading) _buildResultsSection(ctrl),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'AI Smart Car Recommender',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Entrez 3 mots-clés décrivant votre itinéraire (terrain, type de voyage, préférences). '
            'Notre IA Groq analyse vos besoins et recommande les 7 modèles les plus adaptés.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(CarRecommendationController ctrl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vos 3 critères de voyage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _k1Controller,
                decoration: InputDecoration(
                  labelText: 'Mot-clé 1 (ex: Terrain)',
                  hintText: 'montagne, désert, ville, autoroute, neige...',
                  prefixIcon: const Icon(Icons.terrain, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _k2Controller,
                decoration: InputDecoration(
                  labelText: 'Mot-clé 2 (ex: Contexte du trajet)',
                  hintText: 'rocheux, famille, aventure, solo, couple...',
                  prefixIcon: const Icon(Icons.explore, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _k3Controller,
                decoration: InputDecoration(
                  labelText: 'Mot-clé 3 (ex: Exigence ou Confort)',
                  hintText: 'famille, spacieux, 4x4, économique, luxe...',
                  prefixIcon: const Icon(Icons.tune, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Suggestions rapides :',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _presetChip('🏔️ Montagne / Rocheux / Famille', 'montagne', 'rocheux', 'famille'),
                  _presetChip('🏜️ Désert / Sable / Aventure', 'désert', 'sable', 'aventure'),
                  _presetChip('🏙️ Ville / Économique / Solo', 'ville', 'économique', 'solo'),
                  _presetChip('❄️ Neige / 4x4 / Confort', 'neige', '4x4', 'confort'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.psychology, size: 22),
                  label: const Text(
                    'Recommander 7 Véhicules',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: ctrl.isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, String k1, String k2, String k3) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.indigo.withValues(alpha: 0.06),
      side: BorderSide(color: Colors.indigo.withValues(alpha: 0.2)),
      onPressed: () => _applyPreset(k1, k2, k3),
    );
  }

  Widget _buildLoadingSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        width: double.infinity,
        child: const Column(
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              'Analyse IA en cours...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Le modèle Groq sélectionne et classe les 7 véhicules les plus performants pour vos critères.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(CarRecommendationController ctrl) {
    final isKeyError = ctrl.errorMessage?.contains('Clé API') ?? false;

    return Card(
      color: const Color(0xFFFFEBEE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEF9A9A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Une erreur est survenue',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ctrl.errorMessage ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isKeyError)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text('Entrer la clé API'),
                    onPressed: () => _showApiKeyDialog(context),
                  ),
                if (isKeyError) const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Réessayer'),
                  onPressed: () => ctrl.retry(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(CarRecommendationController ctrl) {
    final resp = ctrl.response!;
    final items = resp.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro Card
        if (resp.intro.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyse de vos besoins par l\'IA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resp.intro,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top 7 Modèles Recommandés (${items.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Triés par pertinence',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 7 Cards
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildCarCard(index + 1, item);
        }),

        // General Note / Disclaimer
        if (resp.generalNote.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resp.generalNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCarCard(int rank, CarRecommendationItem car) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFD4AF37); // Or
    } else if (rank == 2) {
      rankColor = const Color(0xFF8E8E93); // Argent
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.indigo;
    }

    Color scoreColor;
    if (car.suitabilityScore >= 90) {
      scoreColor = const Color(0xFF2E7D32); // Vert
    } else if (car.suitabilityScore >= 80) {
      scoreColor = const Color(0xFF1976D2); // Bleu
    } else {
      scoreColor = const Color(0xFFE65100); // Orange
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Rank badge + Car Name + Score badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          car.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Suitability score badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${car.suitabilityScore}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Pertinence',
                        style: TextStyle(fontSize: 9, color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Short explanation / reason
            if (car.reasons.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  car.reasons,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Advantages list
            if (car.advantages.isNotEmpty) ...[
              const Text(
                'Avantages majeurs pour ce voyage :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ...car.advantages.map((adv) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 15, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            adv,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
            ],

            // Limitations list
            if (car.limitations.isNotEmpty) ...[
              const Text(
                'Limites & Précautions :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ...car.limitations.map((lim) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 15, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lim,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            // Action button to reserve
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  elevation: 0,
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text('Réserver pour ce trajet (${car.fullName})'),
                onPressed: () {
                  // Navigation vers le formulaire de réservation
                  Navigator.pushNamed(context, AppRoutes.form);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recherche d\'un véhicule de type "${car.fullName}" dans la flotte locale...',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
