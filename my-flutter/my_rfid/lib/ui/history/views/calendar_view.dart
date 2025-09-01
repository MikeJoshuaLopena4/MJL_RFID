import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../../../theme/color_palette.dart';

class CalendarView extends StatefulWidget {
  final CardItem selectedCard;
  final DateTime calendarViewDate;
  final Future<bool> Function(DateTime, String) hasLogsForDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const CalendarView({
    super.key,
    required this.selectedCard,
    required this.calendarViewDate,
    required this.hasLogsForDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.calendarViewDate;
  }

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendarViewDate != widget.calendarViewDate) {
      _currentMonth = widget.calendarViewDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startingWeekday = firstDay.weekday;

    List<Widget> dayWidgets = [];

    // Add day headers
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (var day in days) {
      dayWidgets.add(
        Container(
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorPalette.text600,
            ),
          ),
        ),
      );
    }

    // Add empty cells for days before the first day of month
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final currentDate = DateTime(year, month, day);

      dayWidgets.add(
        FutureBuilder<bool>(
          future: widget.hasLogsForDate(currentDate, widget.selectedCard.id),
          builder: (context, snapshot) {
            final hasLogs = snapshot.data ?? false;

            return GestureDetector(
              onTap: hasLogs
                  ? () {
                      widget.onDateSelected(currentDate);
                    }
                  : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isToday(currentDate)
                      ? ColorPalette.primary100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _isToday(currentDate)
                      ? Border.all(color: ColorPalette.primary500)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        color: hasLogs
                            ? ColorPalette.text800
                            : ColorPalette.text400,
                        fontWeight: _isToday(currentDate)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (hasLogs)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: ColorPalette.accent500,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      color: ColorPalette.background50,
      child: Column(
        children: [
          // Month navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newDate = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    setState(() {
                      _currentMonth = newDate;
                    });
                    widget.onMonthChanged(newDate);
                  },
                ),
                Text(
                  _formatMonthYear(_currentMonth),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.text800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final newDate = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    setState(() {
                      _currentMonth = newDate;
                    });
                    widget.onMonthChanged(newDate);
                  },
                ),
              ],
            ),
          ),

          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: dayWidgets,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatMonthYear(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}