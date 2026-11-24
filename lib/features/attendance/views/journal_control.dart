import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JournalControl extends StatelessWidget {
  const JournalControl({required this.label, required this.value, required this.tolerance, required this.disabled, required this.onTime, required this.onTolerance, super.key});
  final String label;
  final TimeOfDay value;
  final int tolerance;
  final bool disabled;
  final VoidCallback onTime;
  final ValueChanged<String> onTolerance;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 248,
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: disabled ? null : onTime,
              icon: const Icon(Icons.schedule, size: 16),
              label: Text(
                '$label ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: TextFormField(
              key: ValueKey('$label-$tolerance'),
              initialValue: '$tolerance',
              enabled: !disabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Tol.'),
              onChanged: onTolerance,
            ),
          ),
          const Text(' min'),
        ]),
      );
}
