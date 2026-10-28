import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import '../models/attendance_presentation.dart';

class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar(
      {required this.month,
      required this.days,
      required this.onSelected,
      this.selected,
      super.key});
  final DateTime month;
  final List<ServerAttendanceCalendarDay> days;
  final ValueChanged<DateTime> onSelected;
  final DateTime? selected;
  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = ((leading + count) / 7).ceil() * 7;
    final byDate = {for (final day in days) day.date: day};
    return LayoutBuilder(
        builder: (context, constraints) => Column(children: [
              Row(children: [
                for (final label in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                  Expanded(
                      child: Center(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(label,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)))))
              ]),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      mainAxisExtent: constraints.maxWidth < 600 ? 74 : 82),
                  itemBuilder: (context, index) {
                    final number = index - leading + 1;
                    if (number < 1 || number > count) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(month.year, month.month, number);
                    final item = byDate[date];
                    return Semantics(
                        excludeSemantics: true,
                        label:
                            '${attendanceDate(date)} ${item == null ? 'Fuera del período recibido' : attendanceStatusLabel(item.status)}',
                        button: item != null,
                        child: Material(
                            color: selected == date
                                ? UiColors.primarySoft.withOpacity(.35)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                    color: selected == date
                                        ? UiColors.primary
                                        : UiColors.borderLight)),
                            child: InkWell(
                                key: ValueKey(
                                    'calendar-${date.toIso8601String().split('T').first}'),
                                onTap: item == null
                                    ? null
                                    : () => onSelected(date),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Text('$number',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: item == null
                                                        ? UiColors.textMuted
                                                        : UiColors
                                                            .textPrimary)),
                                            const Spacer(),
                                            if (item != null)
                                              Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          attendanceStatusColor(
                                                              item.status),
                                                      shape: BoxShape.circle))
                                          ]),
                                          const SizedBox(height: 4),
                                          if (item != null) ...[
                                            if (constraints.maxWidth < 600) ...[
                                              Text(
                                                  attendanceTime(
                                                      item.firstMark),
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                  maxLines: 1),
                                              Text(
                                                  attendanceTime(item.lastMark),
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                  maxLines: 1),
                                            ] else
                                              Text(
                                                  '${attendanceTime(item.firstMark)} · ${attendanceTime(item.lastMark)}',
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                          ],
                                        ])))));
                  }),
            ]));
  }
}
