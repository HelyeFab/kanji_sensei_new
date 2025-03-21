import 'package:flutter/material.dart';
import '../../domain/entities/kanji.dart';
import '../theme/app_colors.dart';
import 'save_word_modal.dart';

class KanjiDetailCard extends StatelessWidget {
  final Kanji kanji;
  final VoidCallback onTap;

  const KanjiDetailCard({
    super.key,
    required this.kanji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kanji.character,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.save, color: AppColors.primary, size: 32),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SaveWordModal(
                              wordDetails: {
                                'word': kanji.character,
                                'partOfSpeech': 'Kanji',
                                'translation': kanji.meanings.join(', '),
                                'example': 'On: ${kanji.onReadings.join(", ")}\nKun: ${kanji.kunReadings.join(", ")}',
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailSection('Meanings', kanji.meanings.join(', ')),
                _buildDetailSection('On Readings', kanji.onReadings.join(', ')),
                _buildDetailSection('Kun Readings', kanji.kunReadings.join(', ')),
                _buildDetailSection('Stroke Count', kanji.strokeCount.toString()),
                _buildDetailSection('JLPT Level', 'N${kanji.jlptLevel}'),
                if (kanji.grade != null)
                  _buildDetailSection('Grade', kanji.grade.toString()),
                if (kanji.heisigEn != null)
                  _buildDetailSection('Heisig Keyword', kanji.heisigEn!),
                if (kanji.nameReadings.isNotEmpty)
                  _buildDetailSection('Name Readings', kanji.nameReadings.join(', ')),
                if (kanji.notes.isNotEmpty)
                  _buildDetailSection('Notes', kanji.notes.join('\n')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
