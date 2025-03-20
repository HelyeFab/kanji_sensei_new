import '../entities/saved_word.dart';

class SpacedRepetitionService {
  // SM-2 algorithm parameters
  static const double _minEaseFactor = 1.3;
  static const int _maxInterval = 365; // Maximum interval in days

  // Calculate the next review date for a word based on its difficulty rating
  SavedWord calculateNextReview(SavedWord word, int difficulty) {
    // Increment repetitions
    final repetitions = word.repetitions + 1;

    // Calculate new ease factor based on difficulty
    // 0 = Hard, 1 = Good, 2 = Easy
    double easeFactor = word.easeFactor;
    if (difficulty == 0) {
      // Hard - decrease ease factor
      easeFactor = word.easeFactor - 0.15;
    } else if (difficulty == 2) {
      // Easy - increase ease factor
      easeFactor = word.easeFactor + 0.15;
    }
    // Ensure ease factor doesn't go below minimum
    easeFactor = easeFactor < _minEaseFactor ? _minEaseFactor : easeFactor;

    // Calculate new interval
    int interval;
    int progress = word.progress;

    if (difficulty == 0) {
      // Hard - reset interval
      interval = 1;
      // If progress is already at learning or higher, keep it there
      progress = progress > 0 ? 1 : 0;
    } else {
      // Good or Easy
      if (repetitions == 1) {
        interval = 1;
        progress = 1; // Learning
      } else if (repetitions == 2) {
        interval = 3;
        progress = 1; // Still learning
      } else {
        // Calculate new interval based on previous interval and ease factor
        interval = (word.interval * easeFactor).round();
        
        // Cap interval at maximum
        interval = interval > _maxInterval ? _maxInterval : interval;
        
        // Update progress if interval is long enough
        if (interval >= 21) {
          progress = 2; // Learned
        } else {
          progress = 1; // Still learning
        }
      }
    }

    // Create updated word
    return word.copyWith(
      lastReviewed: DateTime.now(),
      repetitions: repetitions,
      easeFactor: easeFactor,
      interval: interval,
      progress: progress,
      difficulty: difficulty,
    );
  }

  // Get the next review date for a word
  DateTime getNextReviewDate(SavedWord word) {
    final lastReviewed = word.lastReviewed ?? DateTime.now();
    return lastReviewed.add(Duration(days: word.interval));
  }

  // Check if a word is due for review
  bool isDue(SavedWord word) {
    final now = DateTime.now();
    final nextReview = getNextReviewDate(word);
    return now.isAfter(nextReview) || now.isAtSameMomentAs(nextReview);
  }

  // Get all words that are due for review
  List<SavedWord> getDueWords(List<SavedWord> words) {
    return words.where((word) => isDue(word)).toList();
  }
}
