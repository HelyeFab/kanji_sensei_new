import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Sets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Study sets grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStudySetCard(
                    title: 'Basic Phrases',
                    count: 25,
                    color: const Color(0xFFF8C4C6),
                  ),
                  _buildStudySetCard(
                    title: 'Food & Dining',
                    count: 42,
                    color: const Color(0xFFB5D8EB),
                  ),
                  _buildStudySetCard(
                    title: 'Travel',
                    count: 38,
                    color: const Color(0xFFD0F0C0),
                  ),
                  _buildStudySetCard(
                    title: 'Business',
                    count: 30,
                    color: const Color(0xFFFFF0C0),
                  ),
                  _buildStudySetCard(
                    title: 'Everyday Verbs',
                    count: 50,
                    color: const Color(0xFFE6E6FA),
                  ),
                  _buildStudySetCard(
                    title: 'Create New Set',
                    count: null,
                    color: const Color(0xFFEEEEEE),
                    isAddNew: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudySetCard({
    required String title,
    required int? count,
    required Color color,
    bool isAddNew = false,
  }) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isAddNew)
              const Icon(
                Icons.add_circle,
                size: 32,
                color: AppColors.primary,
              )
            else
              Text(
                '$count words',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
