import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WordList extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final int wordCount;

  const WordList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUpdated,
    this.wordCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        lastUpdated,
        wordCount,
      ];

  WordList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? wordCount,
  }) {
    return WordList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  factory WordList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordList(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      wordCount: data['wordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
      'wordCount': wordCount,
    };
  }
}
