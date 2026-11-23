import 'package:flutter/material.dart';

class JournalControl extends StatelessWidget {
  const JournalControl({required this.label, required this.value, required this.tolerance, required this.disabled, required this.onTime, required this.onTolerance, super.key});
  final String label; final TimeOfDay value; final int tolerance; final bool disabled; final VoidCallback onTime; final ValueChanged<String> onTolerance;
  @override Widget build(BuildContext context) => SizedBox(width: 235, child: Row(children: [
    Expanded(child: OutlinedButton(onPressed: disabled ? null : onTime, child: Text('$label ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'))),
    const SizedBox(width: 4), SizedBox(width: 55, child: TextFormField(initialValue: '$tolerance', enabled: !disabled, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tol.'), onChanged: onTolerance)), const Text(' min')
  ]));
}
