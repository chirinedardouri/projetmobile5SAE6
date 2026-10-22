/// Modèle représentant un véhicule disponible dans l'application.
class MockVehicle {
  final int id;
  final String brand;
  final String model;
  final String category;
  final double defaultPricePerDay;
  final String plateNumber;

  const MockVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.defaultPricePerDay,
    required this.plateNumber,
  });

  String get fullName => '$brand $model';
  String get displayName => '$brand $model (N° $id - $plateNumber)';

  static MockVehicle? findById(int? id) {
    if (id == null) return null;
    try {
      return hardcodedVehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// ============================================================================
/// LISTE DES 5 VÉHICULES EN DUR HARDCODED
/// ============================================================================
const List<MockVehicle> hardcodedVehicles = [
  MockVehicle(
    id: 101,
    brand: 'Toyota',
    model: 'Yaris',
    category: 'Citadine Économique',
    defaultPricePerDay: 95.0,
    plateNumber: '210 TN 1010',
  ),
  MockVehicle(
    id: 102,
    brand: 'Volkswagen',
    model: 'Golf 8',
    category: 'Berline Compacte',
    defaultPricePerDay: 140.0,
    plateNumber: '215 TN 2020',
  ),
  MockVehicle(
    id: 103,
    brand: 'Dacia',
    model: 'Duster',
    category: 'SUV Tout-Terrain',
    defaultPricePerDay: 130.0,
    plateNumber: '218 TN 3030',
  ),
  MockVehicle(
    id: 104,
    brand: 'Renault',
    model: 'Clio 5',
    category: 'Citadine Polyvalente',
    defaultPricePerDay: 85.0,
    plateNumber: '220 TN 4040',
  ),
  MockVehicle(
    id: 105,
    brand: 'Hyundai',
    model: 'Tucson',
    category: 'Grand SUV Familial',
    defaultPricePerDay: 180.0,
    plateNumber: '224 TN 5050',
  ),
];
