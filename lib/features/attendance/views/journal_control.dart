import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JournalControl extends StatelessWidget {
  const JournalControl({
    required this.label,
    required this.value,
    required this.tolerance,
    required this.disabled,
    required this.width,
    required this.onTime,
    required this.onTolerance,
    super.key,
  });
  final String label;
  final TimeOfDay value;
  final int tolerance;
  final bool disabled;
  final double width;
  final VoidCallback onTime;
  final ValueChanged<String> onTolerance;

  @override
  Widget build(BuildContext context) {
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return SizedBox(
      width: width,
      child: Row(children: [
        Expanded(
          child: Tooltip(
            message: '$label · $time',
            child: OutlinedButton(
              onPressed: disabled ? null : onTime,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 54,
          child: TextFormField(
            key: ValueKey('$label-$tolerance'),
            initialValue: '$tolerance',
            enabled: !disabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.bodySmall,
            decoration: const InputDecoration(
              labelText: 'Tol.',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            onChanged: onTolerance,
          ),
        ),
        const SizedBox(width: 3),
        Text('min', style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }
}
