class Reservation {
  final int? id;
  final int userId;
  final int vehicleId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;
  final String status; // EN_ATTENTE, CONFIRMEE, EN_COURS, TERMINEE, ANNULEE
  final DateTime createdAt;

  Reservation({
    this.id,
    required this.userId,
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
    required this.totalCost,
    this.status = 'EN_ATTENTE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'vehicle_id': vehicleId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_cost': totalCost,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory Reservation.fromMap(Map<String, dynamic> m) => Reservation(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        vehicleId: m['vehicle_id'] as int,
        startDate: DateTime.parse(m['start_date']),
        endDate: DateTime.parse(m['end_date']),
        totalCost: (m['total_cost'] as num).toDouble(),
        status: m['status'],
        createdAt: DateTime.parse(m['created_at']),
      );
}