import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'User Name',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'user@example.com',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Stats section
              Text(
                'Your Stats',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 16),
              
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Words Learned', '128'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Study Streak', '7 days'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Settings section
              Text(
                'Settings',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 16),
              
              // Settings options
              _buildSettingsOption(Icons.notifications_outlined, 'Notifications'),
              _buildSettingsOption(Icons.dark_mode_outlined, 'Dark Mode'),
              _buildSettingsOption(Icons.language_outlined, 'Language'),
              _buildSettingsOption(Icons.help_outline, 'Help & Support'),
              _buildSettingsOption(Icons.logout_outlined, 'Log Out'),
              
              // Add some bottom padding for scrolling
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Text(
            title,
            style: AppTextStyles.bodyLarge,
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
