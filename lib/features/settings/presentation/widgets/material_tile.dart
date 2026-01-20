import 'package:flutter/material.dart';

class MaterialTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Function()? onTap;
  final bool? showTrailing;
  const MaterialTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle ?? ''),
          leading: Icon(icon),
          trailing: showTrailing!
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
