import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/reservation_controller.dart';
import '../../models/mock_vehicles.dart';

/// Sélecteur de dates de type Airbnb qui bloque et grise
/// automatiquement toutes les dates où le véhicule est déjà réservé.
class AirbnbDatePickerDialog extends StatefulWidget {
  final int vehicleId;
  final ReservationController controller;
  final DateTimeRange? initialRange;
  final int? excludeReservationId;

  const AirbnbDatePickerDialog({
    super.key,
    required this.vehicleId,
    required this.controller,
    this.initialRange,
    this.excludeReservationId,
  });

  @override
  State<AirbnbDatePickerDialog> createState() => _AirbnbDatePickerDialogState();
}

class _AirbnbDatePickerDialogState extends State<AirbnbDatePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  final _monthFmt = DateFormat('MMMM yyyy', 'fr_FR');
  final _dayFmt = DateFormat('dd MMM', 'fr_FR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    if (widget.initialRange != null) {
      _startDate = DateTime(
        widget.initialRange!.start.year,
        widget.initialRange!.start.month,
        widget.initialRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialRange!.end.year,
        widget.initialRange!.end.month,
        widget.initialRange!.end.day,
      );
    }
  }

  bool _isDayInPast(DateTime day) {
    final today = DateTime.now();
    final zeroToday = DateTime(today.year, today.month, today.day);
    return day.isBefore(zeroToday);
  }

  bool _isDayReserved(DateTime day) {
    return widget.controller.isDateOccupied(
      widget.vehicleId,
      day,
      excludeId: widget.excludeReservationId,
    );
  }

  bool _rangeContainsReserved(DateTime start, DateTime end) {
    var cur = start.add(const Duration(days: 1));
    while (cur.isBefore(end)) {
      if (_isDayReserved(cur)) return true;
      cur = cur.add(const Duration(days: 1));
    }
    return false;
  }

  void _onDaySelected(DateTime day) {
    if (_isDayInPast(day)) return;

    if (_isDayReserved(day)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ce véhicule est déjà réservé à cette date.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Premier clic : sélection du début
        _startDate = day;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (day.isBefore(_startDate!)) {
          // L'utilisateur a cliqué sur une date antérieure : on redéfinit le début
          _startDate = day;
        } else if (day.isAtSameMomentAs(_startDate!)) {
          // Même date : réinitialise
          _startDate = null;
        } else {
          // Vérification Airbnb : y a-t-il une réservation au milieu de la plage ?
          if (_rangeContainsReserved(_startDate!, day)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⛔ Impossible : des réservations existent déjà dans cette plage.',
                ),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            _endDate = day;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = MockVehicle.findById(widget.vehicleId);
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday; // 1 = Lundi, 7 = Dimanche

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre & Info Véhicule
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calendrier des disponibilités',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicle != null
                            ? '${vehicle.fullName} (N° ${vehicle.id})'
                            : 'Véhicule N° ${widget.vehicleId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bandeau d'état (style Airbnb)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _startDate != null && _endDate != null
                    ? Colors.teal.withValues(alpha: 0.1)
                    : Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _startDate != null && _endDate != null
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 18,
                    color: _startDate != null && _endDate != null
                        ? Colors.teal
                        : Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? '1. Touchez une date de prise en charge'
                          : _endDate == null
                              ? '2. Touchez une date de restitution'
                              : 'Du ${_dayFmt.format(_startDate!)} au ${_dayFmt.format(_endDate!)} (${_endDate!.difference(_startDate!).inDays} j)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _startDate != null && _endDate != null
                            ? Colors.teal.shade900
                            : Colors.indigo.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Navigation Mois (‹ Mois Année ›)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  _monthFmt.format(_currentMonth).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // En-têtes jours de la semaine (Lun - Dim)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekHeader('L'),
                _WeekHeader('M'),
                _WeekHeader('M'),
                _WeekHeader('J'),
                _WeekHeader('V'),
                _WeekHeader('S'),
                _WeekHeader('D'),
              ],
            ),
            const SizedBox(height: 6),

            // Grille des jours
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.15,
              ),
              itemCount: (firstDayWeekday - 1) + daysInMonth,
              itemBuilder: (ctx, index) {
                // Cases vides avant le 1er du mois
                if (index < firstDayWeekday - 1) {
                  return const SizedBox.shrink();
                }
                final dayNum = index - (firstDayWeekday - 1) + 1;
                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNum,
                );
                return _buildDayTile(date, dayNum);
              },
            ),
            const SizedBox(height: 12),

            // Légende explicative Airbnb
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem(Colors.green.shade100, Colors.green.shade800, 'Disponible'),
                _legendItem(Colors.red.shade100, Colors.red.shade800, 'Réservé (Bloqué)'),
                _legendItem(Colors.indigo, Colors.white, 'Sélection'),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Effacer'),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _startDate != null && _endDate != null
                      ? () {
                          Navigator.pop(
                            context,
                            DateTimeRange(start: _startDate!, end: _endDate!),
                          );
                        }
                      : null,
                  child: const Text('Valider la période'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(DateTime date, int dayNum) {
    final isPast = _isDayInPast(date);
    final isReserved = _isDayReserved(date);

    final isStart = _startDate != null &&
        DateUtils.isSameDay(date, _startDate!);
    final isEnd = _endDate != null &&
        DateUtils.isSameDay(date, _endDate!);
    final inRange = _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    Color? bg;
    Color fg = Colors.black87;
    BoxBorder? border;
    TextDecoration? decor;

    if (isStart || isEnd) {
      bg = Colors.indigo;
      fg = Colors.white;
    } else if (inRange) {
      bg = Colors.indigo.withValues(alpha: 0.15);
      fg = Colors.indigo.shade900;
    } else if (isReserved) {
      // Style Airbnb : jour déjà occupé = rouge pâle barré
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
      decor = TextDecoration.lineThrough;
      border = Border.all(color: const Color(0xFFFFCDD2));
    } else if (isPast) {
      fg = Colors.grey.shade400;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isPast || isReserved ? null : () => _onDaySelected(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                color: fg,
                fontWeight: isStart || isEnd || isReserved
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12,
                decoration: decor,
                decorationColor: const Color(0xFFC62828),
                decorationThickness: 2,
              ),
            ),
            if (isReserved)
              const Text(
                'Occupé',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final String label;
  const _WeekHeader(this.label);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
