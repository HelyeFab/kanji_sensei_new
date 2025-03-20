import 'package:flutter/material.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/saved_word.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../data/repositories/saved_words_repository.dart';
import '../widgets/flashcard/flashcard.dart';

class StudySessionScreen extends StatefulWidget {
  final List<SavedWord> words;

  const StudySessionScreen({
    super.key,
    required this.words,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late List<FlipCardController> _flipControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Initialize a flip controller for each word
    _flipControllers = List.generate(
      widget.words.length,
      (_) => FlipCardController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markWord(int difficulty) async {
    final currentWord = widget.words[_currentIndex];
    
    try {
      // Get repositories
      final savedWordsRepository = context.read<SavedWordsRepository>();
      final spacedRepetitionService = SpacedRepetitionService();
      
      // Calculate next review using spaced repetition
      final updatedWord = spacedRepetitionService.calculateNextReview(
        currentWord,
        difficulty,
      );

      // Update word in repository
      await savedWordsRepository.updateWord(updatedWord);
      
      // Move to next word
      final nextIndex = _currentIndex + 1;
      if (nextIndex < widget.words.length) {
        setState(() {
          _currentIndex = nextIndex;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // End of session
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study session completed!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating word: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Study Session (${_currentIndex + 1}/${widget.words.length})',
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: ((_currentIndex + 1) / widget.words.length),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),

          // Flashcards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.words.length,
              itemBuilder: (context, index) {
                final word = widget.words[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Flashcard(
                    word: word.word,
                    definition: word.definition,
                    examples: word.examples,
                    controller: _flipControllers[index],
                    language: word.language,
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _markWord(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hard'),
                ),
                ElevatedButton(
                  onPressed: () => _markWord(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Good'),
                ),
                ElevatedButton(
                  onPressed: () => _markWord(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Easy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
