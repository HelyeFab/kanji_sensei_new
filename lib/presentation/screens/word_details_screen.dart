import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/save_word_modal.dart'; // Import SaveWordModal

class WordDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> wordDetails;

  const WordDetailsScreen({super.key, required this.wordDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary, // Correct AppBar background to primary color
        foregroundColor: AppColors.lightGray, // Set foreground color to lightGray for back button and title
        title: Text(wordDetails['word'] ?? 'Word Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.lightGray), // Set icon color to lightGray
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SaveWordModal(wordDetails: wordDetails);
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Word: ${wordDetails['word'] ?? ''}', style: const TextStyle(fontSize: 20, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Part of Speech: ${wordDetails['partOfSpeech'] ?? ''}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Translation: ${wordDetails['translation'] ?? ''}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Example: ${wordDetails['example'] ?? ''}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
