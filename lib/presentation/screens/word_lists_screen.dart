import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/word_lists_repository.dart';
import '../../domain/entities/word_list.dart';
import '../screens/word_details_screen.dart';

class WordListsScreen extends StatelessWidget {
  const WordListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wordListsRepository = getIt<WordListsRepository>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightGray,
        title: const Text('My Word Lists'),
      ),
      body: StreamBuilder<List<WordList>>(
        stream: wordListsRepository.getWordLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lists = snapshot.data ?? [];

          if (lists.isEmpty) {
            return const Center(
              child: Text('No word lists yet. Save words to create lists.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordListDetailScreen(list: list),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.book, size: 16),
                            const SizedBox(width: 4),
                            Text('${list.wordCount} words'),
                            const Spacer(),
                            Text(
                              'Created: ${_formatDate(list.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          _showCreateListDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateListDialog(BuildContext context) {
    final wordListsRepository = getIt<WordListsRepository>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New List'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Enter list name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await wordListsRepository.createWordList(name);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('List "$name" created')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class WordListDetailScreen extends StatelessWidget {
  final WordList list;

  const WordListDetailScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final wordListsRepository = getIt<WordListsRepository>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightGray,
        title: Text(list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: wordListsRepository.getWordsInList(list.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final words = snapshot.data ?? [];

          if (words.isEmpty) {
            return const Center(
              child: Text('No words in this list yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: words.length,
            itemBuilder: (context, index) {
                      final word = words[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Navigate to word details screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WordDetailsScreen(
                                  wordDetails: {
                                    'word': word.word,
                                    'partOfSpeech': '',
                                    'translation': word.definition,
                                    'example': word.examples?.isNotEmpty == true ? word.examples!.first : '',
                                  },
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  word.definition,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (word.examples != null && word.examples!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Example: ${word.examples!.first}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Remove'),
                                      onPressed: () async {
                                        try {
                                          await wordListsRepository.removeWordFromList(
                                            list.id,
                                            word.id,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Word removed from list'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final wordListsRepository = getIt<WordListsRepository>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete List'),
          content: Text('Are you sure you want to delete "${list.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await wordListsRepository.deleteWordList(list.id);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to lists screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('List "${list.name}" deleted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
