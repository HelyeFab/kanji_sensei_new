import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class JlptLevelSelector extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;

  const JlptLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: List.generate(5, (index) {
          final level = 5 - index;
          final isSelected = level == selectedLevel;
          
          BorderRadius borderRadius;
          if (index == 0) {
            borderRadius = const BorderRadius.only(
              topRight: Radius.circular(22),
              bottomRight: Radius.circular(22),
            );
          } else if (index == 4) {
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(22),
              bottomLeft: Radius.circular(22),
            );
          } else {
            borderRadius = BorderRadius.zero;
          }
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onLevelChanged(level),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: borderRadius,
                ),
                alignment: Alignment.center,
                child: Text(
                  'N$level',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
