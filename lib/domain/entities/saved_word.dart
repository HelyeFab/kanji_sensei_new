import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SavedWord extends Equatable {
  final String id;
  final String word;
  final String definition;
  final List<String>? examples;
  final String language;
  final DateTime savedAt;
  final DateTime? lastReviewed;
  final int progress; // 0: new, 1: learning, 2: learned
  final int repetitions;
  final double easeFactor;
  final int interval;
  final int difficulty; // 0: hard, 1: good, 2: easy

  const SavedWord({
    required this.id,
    required this.word,
    required this.definition,
    this.examples,
    required this.language,
    required this.savedAt,
    this.lastReviewed,
    this.progress = 0,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.difficulty = 1,
  });

  @override
  List<Object?> get props => [
        id,
        word,
        definition,
        examples,
        language,
        savedAt,
        lastReviewed,
        progress,
        repetitions,
        easeFactor,
        interval,
        difficulty,
      ];

  SavedWord copyWith({
    String? id,
    String? word,
    String? definition,
    List<String>? examples,
    String? language,
    DateTime? savedAt,
    DateTime? lastReviewed,
    int? progress,
    int? repetitions,
    double? easeFactor,
    int? interval,
    int? difficulty,
  }) {
    return SavedWord(
      id: id ?? this.id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      examples: examples ?? this.examples,
      language: language ?? this.language,
      savedAt: savedAt ?? this.savedAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      progress: progress ?? this.progress,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  factory SavedWord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedWord(
      id: doc.id,
      word: data['word'] ?? '',
      definition: data['definition'] ?? '',
      examples: data['examples'] != null
          ? List<String>.from(data['examples'])
          : null,
      language: data['language'] ?? 'ja',
      savedAt: (data['savedAt'] as Timestamp).toDate(),
      lastReviewed: data['lastReviewed'] != null
          ? (data['lastReviewed'] as Timestamp).toDate()
          : null,
      progress: data['progress'] ?? 0,
      repetitions: data['repetitions'] ?? 0,
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
      interval: data['interval'] ?? 0,
      difficulty: data['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'word': word,
      'definition': definition,
      'examples': examples,
      'language': language,
      'savedAt': Timestamp.fromDate(savedAt),
      'lastReviewed': lastReviewed != null
          ? Timestamp.fromDate(lastReviewed!)
          : null,
      'progress': progress,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'interval': interval,
      'difficulty': difficulty,
    };
  }
}
