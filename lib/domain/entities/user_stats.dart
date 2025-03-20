import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final int savedWords;
  final int readingStreak;
  final List<DateTime> readDates;
  final DateTime? lastReadDate;
  final DateTime? lastUpdated;

  const UserStats({
    this.savedWords = 0,
    this.readingStreak = 0,
    this.readDates = const <DateTime>[],
    this.lastReadDate,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        savedWords,
        readingStreak,
        readDates,
        lastReadDate,
        lastUpdated,
      ];

  UserStats copyWith({
    int? savedWords,
    int? readingStreak,
    List<DateTime>? readDates,
    DateTime? lastReadDate,
    DateTime? lastUpdated,
  }) {
    return UserStats(
      savedWords: savedWords ?? this.savedWords,
      readingStreak: readingStreak ?? this.readingStreak,
      readDates: readDates ?? this.readDates,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStats(
      savedWords: data['savedWords'] ?? 0,
      readingStreak: data['readingStreak'] ?? 0,
      readDates: _dateTimeListFromJson(data['readDates']),
      lastReadDate: data['lastReadDate'] != null
          ? (data['lastReadDate'] as Timestamp).toDate()
          : null,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'savedWords': savedWords,
      'readingStreak': readingStreak,
      'readDates': readDates.map((date) => Timestamp.fromDate(date)).toList(),
      'lastReadDate': lastReadDate != null
          ? Timestamp.fromDate(lastReadDate!)
          : null,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool isStreakActive() {
    if (lastReadDate == null) return false;

    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day - 1,
    );

    final lastRead = DateTime(
      lastReadDate!.year,
      lastReadDate!.month,
      lastReadDate!.day,
    );

    return lastRead.isAtSameMomentAs(yesterday) || lastRead.isAtSameMomentAs(now);
  }
}

List<DateTime> _dateTimeListFromJson(dynamic json) {
  if (json == null) return [];
  if (json is! List) return [];
  
  return json.map((item) {
    if (item is Timestamp) {
      return item.toDate();
    }
    return DateTime.now(); // fallback
  }).toList();
}
