import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/saved_words_repository.dart';
import '../../domain/entities/saved_word.dart';
import 'study_session_screen.dart';

class WordCollectionScreen extends StatelessWidget {
  const WordCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedWordsRepository = Provider.of<SavedWordsRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Words'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SavedWord>>(
        stream: savedWordsRepository.getSavedWords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading words: ${snapshot.error}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }

          final words = snapshot.data ?? [];

          if (words.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved words yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save words from the dictionary to study them',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Progress stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<Map<String, int>>(
                  stream: savedWordsRepository.getWordProgressCounts(),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {
                      'new': 0,
                      'learning': 0,
                      'learned': 0,
                    };

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          context,
                          'New',
                          stats['new'] ?? 0,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          'Learning',
                          stats['learning'] ?? 0,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          'Learned',
                          stats['learned'] ?? 0,
                          Colors.green,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Word list
              Expanded(
                child: ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return _buildWordCard(context, word);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final savedWordsRepository = Provider.of<SavedWordsRepository>(context, listen: false);
          final words = await savedWordsRepository.getSavedWordsList();
          
          if (context.mounted && words.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudySessionScreen(words: words),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No words to study'),
              ),
            );
          }
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, SavedWord word) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          word.word,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          word.definition,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressIndicator(word.progress),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(context, word);
              },
            ),
          ],
        ),
        onTap: () {
          // Show word details
        },
      ),
    );
  }

  Widget _buildProgressIndicator(int progress) {
    Color color;
    IconData icon;

    switch (progress) {
      case 0:
        color = Colors.blue;
        icon = Icons.fiber_new;
        break;
      case 1:
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case 2:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Icon(
      icon,
      color: color,
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    SavedWord word,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Word'),
          content: Text('Are you sure you want to delete "${word.word}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      try {
        final savedWordsRepository = Provider.of<SavedWordsRepository>(
          context,
          listen: false,
        );
        await savedWordsRepository.removeWord(word.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Word deleted'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting word: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
