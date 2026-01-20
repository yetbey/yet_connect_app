import 'package:flutter/material.dart';

class MaterialSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool? value;
  final Function(bool) onChanged;

  const MaterialSwitchTile({
    super.key,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: SwitchListTile(
          title: Text(title),
          subtitle: Text(subtitle!),
          value: value!,
          onChanged: onChanged,
          secondary: Icon(icon),
          activeThumbColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
