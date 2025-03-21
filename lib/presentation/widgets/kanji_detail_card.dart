import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/kanji.dart';
import '../theme/app_colors.dart';
import '../blocs/kanji/kanji_bloc.dart';
import '../blocs/kanji/kanji_event.dart';

class KanjiDetailCard extends StatelessWidget {
  final Kanji kanji;
  final VoidCallback? onClose;

  const KanjiDetailCard({
    super.key, 
    required this.kanji,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primary, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Center(
                    child: Text(
                      kanji.character,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: () {
                        print('Close button pressed!');
                        // Only use the callback approach
                        if (onClose != null) {
                          print('Calling onClose callback');
                          onClose!();
                        } else {
                          print('onClose callback is null!');
                        }
                      },
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
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
