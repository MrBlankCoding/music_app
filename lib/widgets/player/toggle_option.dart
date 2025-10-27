import 'package:flutter/material.dart';

class ToggleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Stream<bool> stream;
  final VoidCallback onToggle;

  const ToggleOption({
    super.key,
    required this.icon,
    required this.title,
    required this.stream,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: stream,
      initialData: false,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final color = isEnabled ? Colors.deepOrange : Colors.white;

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          trailing: Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.deepOrange,
          ),
          onTap: onToggle,
        );
      },
    );
  }
}
