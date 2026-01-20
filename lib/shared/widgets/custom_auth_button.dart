import 'package:flutter/material.dart';

class CustomAuthButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Function()? onTap;
  const CustomAuthButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.surface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
