import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class KanjiSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool enabled;
  final String hintText;

  const KanjiSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.enabled = true,
    this.hintText = 'Search for a word',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGray, // Matcha background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          hintStyle: AppTextStyles.searchHint
              .copyWith(color: AppColors.textPrimary),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(Icons.search, color: AppColors.textPrimary, size: 20),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}
