import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../screens/word_details_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DictionaryCard extends StatelessWidget {
  final String word;
  final String partOfSpeech;
  final String translation;
  final String example;
  final Map<String, dynamic> result;

  const DictionaryCard({
    super.key,
    required this.word,
    required this.partOfSpeech,
    required this.translation,
    required this.example,
    required this.result, 
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordDetailsScreen(wordDetails: result),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primary, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                translation,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                example,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
