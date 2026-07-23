import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

class RoomAvailabilityCalendarDialog extends StatefulWidget {
  final String roomId;
  final String roomNumber;
  final List<BookingModel> existingBookings;
  final DateTime initialCheckIn;
  final DateTime initialCheckOut;

  const RoomAvailabilityCalendarDialog({
    super.key,
    required this.roomId,
    required this.roomNumber,
    required this.existingBookings,
    required this.initialCheckIn,
    required this.initialCheckOut,
  });

  @override
  State<RoomAvailabilityCalendarDialog> createState() =>
      _RoomAvailabilityCalendarDialogState();
}

class _RoomAvailabilityCalendarDialogState
    extends State<RoomAvailabilityCalendarDialog> {
  late DateTime _displayedMonth;
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedCheckIn = DateTime(
      widget.initialCheckIn.year,
      widget.initialCheckIn.month,
      widget.initialCheckIn.day,
    );
    _selectedCheckOut = DateTime(
      widget.initialCheckOut.year,
      widget.initialCheckOut.month,
      widget.initialCheckOut.day,
    );
  }

  // Returns matching booking if room is occupied/booked for stay night on date 'd'
  BookingModel? _getBookingForDate(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final b in widget.existingBookings) {
      if (b.roomId != widget.roomId) continue;
      final st = b.status.toLowerCase();
      if (st == 'completed' || st == 'cancelled' || st == 'checked_out') {
        continue;
      }
      final start = DateTime(
        b.checkInDate.year,
        b.checkInDate.month,
        b.checkInDate.day,
      );
      final end = DateTime(
        b.checkOutDate.year,
        b.checkOutDate.month,
        b.checkOutDate.day,
      );

      // Booked from start date to end date INCLUSIVE (July 7 to July 10 are all RED)
      if (!target.isBefore(start) && !target.isAfter(end)) return b;
    }
    return null;
  }

  // Returns matching booking if date 'd' is the check-out date of an active booking
  BookingModel? _getCheckoutForDate(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final b in widget.existingBookings) {
      if (b.roomId != widget.roomId) continue;
      final st = b.status.toLowerCase();
      if (st == 'completed' || st == 'cancelled' || st == 'checked_out') {
        continue;
      }
      final end = DateTime(
        b.checkOutDate.year,
        b.checkOutDate.month,
        b.checkOutDate.day,
      );
      if (target.isAtSameMomentAs(end)) return b;
    }
    return null;
  }

  bool _isDateBooked(DateTime day) => _getBookingForDate(day) != null;

  void _onDateTap(DateTime day) {
    final booked = _getBookingForDate(day);
    if (booked != null) {
      setState(() {
        final dateStr = '${day.day}/${day.month}/${day.year}';
        _errorMessage =
            'Already booked on $dateStr (${booked.guestName.isNotEmpty ? booked.guestName : "Guest"})';
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Already booked for ${day.day} ${_getMonthName(day.month)} ${day.year}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;

      // Selection logic:
      if (_selectedCheckIn == null || (_selectedCheckIn != null && _selectedCheckOut != null)) {
        // Start new selection
        _selectedCheckIn = day;
        _selectedCheckOut = null;
      } else if (_selectedCheckIn != null && _selectedCheckOut == null) {
        if (day.isBefore(_selectedCheckIn!)) {
          // If tapped date is before current check-in, make it the new check-in
          _selectedCheckIn = day;
        } else if (day.isAtSameMomentAs(_selectedCheckIn!)) {
          // Double tapped same date -> 1 night stay
          _selectedCheckOut = day.add(const Duration(days: 1));
        } else {
          // Check if any date in range [_selectedCheckIn, day] is booked
          bool rangeHasOverlap = false;
          DateTime curr = _selectedCheckIn!;
          while (curr.isBefore(day)) {
            if (_isDateBooked(curr)) {
              rangeHasOverlap = true;
              break;
            }
            curr = curr.add(const Duration(days: 1));
          }

          if (rangeHasOverlap) {
            _errorMessage = 'Selected range overlaps with an already booked date!';
          } else {
            _selectedCheckOut = day;
          }
        }
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstWeekday =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7; // 0=Sun

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final int nights = (_selectedCheckIn != null && _selectedCheckOut != null)
        ? _selectedCheckOut!.difference(_selectedCheckIn!).inDays.clamp(1, 365)
        : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${widget.roomNumber} Availability',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap dates to select check-in and check-out',
                        style: TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),

            // Legend Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    color: AppColors.error,
                    label: 'Already Booked',
                    hasBorder: true,
                  ),
                  _buildLegendItem(
                    color: AppColors.primary,
                    label: 'Selected Stay',
                    isFilled: true,
                  ),
                  _buildLegendItem(
                    color: AppColors.outlineVariant,
                    label: 'Available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Month Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weekday Header Row
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firstWeekday + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return const SizedBox.shrink();
                }
                final dayNumber = index - firstWeekday + 1;
                final dayDate = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month,
                  dayNumber,
                );

                final isBooked = _isDateBooked(dayDate);
                final isCheckoutDay = _getCheckoutForDate(dayDate) != null;
                final isToday = dayDate.isAtSameMomentAs(todayOnly);
                final isCheckIn = _selectedCheckIn != null &&
                    dayDate.isAtSameMomentAs(_selectedCheckIn!);
                final isCheckOut = _selectedCheckOut != null &&
                    dayDate.isAtSameMomentAs(_selectedCheckOut!);
                final isInRange = _selectedCheckIn != null &&
                    _selectedCheckOut != null &&
                    dayDate.isAfter(_selectedCheckIn!) &&
                    dayDate.isBefore(_selectedCheckOut!);

                // Item Styling
                BoxDecoration decoration;
                TextStyle textStyle;

                if (isBooked) {
                  // RED OUTLINE logic for already booked dates!
                  decoration = BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.error, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  );
                  textStyle = const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                } else if (isCheckIn || isCheckOut) {
                  decoration = BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  );
                  textStyle = const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                } else if (isInRange) {
                  decoration = BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  );
                  textStyle = const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                } else if (isCheckoutDay) {
                  decoration = BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  );
                  textStyle = TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                } else {
                  decoration = BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  );
                  textStyle = TextStyle(
                    color: dayDate.isBefore(todayOnly)
                        ? AppColors.outline
                        : AppColors.onSurface,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  );
                }

                return InkWell(
                  onTap: () => _onDateTap(dayDate),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: decoration,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('$dayNumber', style: textStyle),
                        if (isBooked)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 0),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'BOOKED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        else if (isCheckoutDay && !isCheckIn && !isCheckOut && !isInRange)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 0),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'CHECK OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Error banner if user clicked booked date
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Selection summary & Submit Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCheckIn != null
                            ? 'In: ${_selectedCheckIn!.day} ${_getMonthName(_selectedCheckIn!.month)}'
                            : 'Select Check-in',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedCheckOut != null
                            ? 'Out: ${_selectedCheckOut!.day} ${_getMonthName(_selectedCheckOut!.month)} ($nights N)'
                            : 'Select Check-out',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      (_selectedCheckIn != null && _selectedCheckOut != null)
                          ? () {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: _selectedCheckIn!,
                                  end: _selectedCheckOut!,
                                ),
                              );
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Apply Dates'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isFilled = false,
    bool hasBorder = false,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isFilled ? color : color.withValues(alpha: 0.15),
            border: hasBorder ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
