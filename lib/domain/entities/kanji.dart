import 'package:equatable/equatable.dart';

class Kanji extends Equatable {
  final String character;
  final List<String> onReadings;
  final List<String> kunReadings;
  final List<String> meanings;
  final int strokeCount;
  final int jlptLevel;
  final int? grade;
  final String? unicode;
  final String? heisigEn;
  final List<String> nameReadings;
  final List<String> notes;

  const Kanji({
    required this.character,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    required this.strokeCount,
    required this.jlptLevel,
    this.grade,
    this.unicode,
    this.heisigEn,
    this.nameReadings = const [],
    this.notes = const [],
  });

  factory Kanji.fromJson(Map<String, dynamic> json) {
    return Kanji(
      character: json['kanji'] as String,
      onReadings: List<String>.from(json['on_readings'] ?? []),
      kunReadings: List<String>.from(json['kun_readings'] ?? []),
      meanings: List<String>.from(json['meanings'] ?? []),
      strokeCount: json['stroke_count'] as int,
      jlptLevel: json['jlpt'] as int? ?? 0,
      grade: json['grade'] as int?,
      unicode: json['unicode'] as String?,
      heisigEn: json['heisig_en'] as String?,
      nameReadings: List<String>.from(json['name_readings'] ?? []),
      notes: List<String>.from(json['notes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kanji': character,
      'on_readings': onReadings,
      'kun_readings': kunReadings,
      'meanings': meanings,
      'stroke_count': strokeCount,
      'jlpt': jlptLevel,
      'grade': grade,
      'unicode': unicode,
      'heisig_en': heisigEn,
      'name_readings': nameReadings,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        character,
        onReadings,
        kunReadings,
        meanings,
        strokeCount,
        jlptLevel,
        grade,
        unicode,
        heisigEn,
        nameReadings,
        notes,
      ];
}
