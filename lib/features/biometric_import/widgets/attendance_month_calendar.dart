import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import '../models/attendance_calendar_month.dart';

class AttendanceMonthCalendar extends StatelessWidget {
  const AttendanceMonthCalendar(
      {required this.month, required this.onDaySelected, super.key});
  final AttendanceCalendarMonth month;
  final ValueChanged<AttendanceCalendarDay> onDaySelected;
  static const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static (String, Color, Color) style(CalendarDayStatus status) =>
      switch (status) {
        CalendarDayStatus.normal => (
            'Normal',
            UiColors.success,
            UiColors.successSoft
          ),
        CalendarDayStatus.observation => (
            'Observación',
            UiColors.warning,
            const Color(0xFFFEF3C7)
          ),
        CalendarDayStatus.anomaly => (
            'Anomalía',
            UiColors.danger,
            const Color(0xFFFEE2E2)
          ),
        CalendarDayStatus.noData => (
            'Sin datos',
            UiColors.textMuted,
            const Color(0xFFE5E7EB)
          ),
      };
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, 344.0);
        final narrow = (width - 36) / 7 < 110;
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
                width: width,
                child: Column(children: [
                  Row(children: [
                    for (final label in weekdays)
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: UiColors.textSecondary,
                                      fontWeight: FontWeight.w600))))
                  ]),
                  GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: month.cellCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              mainAxisExtent: 88),
                      itemBuilder: (context, index) {
                        final dayIndex = index - month.leadingEmptyCells;
                        if (dayIndex < 0 || dayIndex >= month.days.length) {
                          return const SizedBox();
                        }
                        final day = month.days[dayIndex];
                        final (label, color, _) = style(day.status);
                        final records = day.analysis?.records ?? [];
                        final times = records
                            .take(2)
                            .map((record) =>
                                DateFormat('HH:mm').format(record.timestamp))
                            .join(' · ');
                        final summary = records.isEmpty
                            ? '—'
                            : narrow && records.length > 1
                                ? '${records.length} reg.'
                                : times;
                        return Tooltip(
                            message:
                                '${DateFormat('dd/MM/yyyy').format(day.date)} · $label · ${records.length} marcaciones',
                            child: Semantics(
                                label:
                                    '${DateFormat('dd/MM/yyyy').format(day.date)}, $label, ${records.length} marcaciones',
                                button: true,
                                child: Material(
                                    color: UiColors.surface,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(
                                            color: UiColors.borderLight)),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: ValueKey(
                                          'calendar-${DateFormat('yyyy-MM-dd').format(day.date)}'),
                                      onTap: () => onDaySelected(day),
                                      child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${day.date.day}',
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize:
                                                                      13))),
                                                  Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                          color: color,
                                                          shape:
                                                              BoxShape.circle))
                                                ]),
                                                const Spacer(),
                                                Text(summary,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        height: 1.2,
                                                        color: UiColors
                                                            .textSecondary)),
                                                if (!narrow &&
                                                    records.length > 2)
                                                  Text(
                                                      '+${records.length - 2} más',
                                                      maxLines: 1,
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          height: 1.2,
                                                          color: UiColors
                                                              .textMuted)),
                                              ])),
                                    ))));
                      }),
                ])));
      });
}
