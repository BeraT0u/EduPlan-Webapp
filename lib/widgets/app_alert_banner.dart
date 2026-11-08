import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAlertBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const AppAlertBanner({
    super.key,
    required this.message,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isError ? AppColors.dangerSurface : AppColors.warningSurface;
    final borderColor = isError ? AppColors.dangerBorder : AppColors.warningBorder;
    final textColor = isError ? AppColors.dangerText : AppColors.warningText;
    final icon = isError ? Icons.error_outline : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
