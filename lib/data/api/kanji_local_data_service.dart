import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/kanji.dart';

@injectable
class KanjiLocalDataService {
  // Map to store the path to the JSON file for each JLPT level
  final Map<int, String> _jlptFilePaths = {
    1: 'lib/assets/kanji_data/jlpt_1/jlpt_1.json',
    2: 'lib/assets/kanji_data/jlpt_2/jlpt_2.json',
    3: 'lib/assets/kanji_data/jlpt_3/jlpt_3.json',
    4: 'lib/assets/kanji_data/jlpt_4/jlpt_4.json',
    5: 'lib/assets/kanji_data/jlpt_5/jlpt_5.json',
  };
  
  // Map to store the paths to the sub-level JSON files
  final Map<String, String> _jlptSubLevelFilePaths = {
    '1_1': 'lib/assets/kanji_data/jlpt_1_1/jlpt_1_1.json',
    '1_2': 'lib/assets/kanji_data/jlpt_1_2/jlpt_1_2.json',
    '1_3': 'lib/assets/kanji_data/jlpt_1_3/jlpt_1_3.json',
    '1_4': 'lib/assets/kanji_data/jlpt_1_4/jlpt_1_4.json',
    '1_5': 'lib/assets/kanji_data/jlpt_1_5/jlpt_1_5.json',
    '1_6': 'lib/assets/kanji_data/jlpt_1_6/jlpt_1_6.json',
    '1_7': 'lib/assets/kanji_data/jlpt_1_7/jlpt_1_7.json',
    '1_8': 'lib/assets/kanji_data/jlpt_1_8/jlpt_1_8.json',
    '1_9': 'lib/assets/kanji_data/jlpt_1_9/jlpt_1_9.json',
    '1_10': 'lib/assets/kanji_data/jlpt_1_10/jlpt_1_10.json',
    '2_1': 'lib/assets/kanji_data/jlpt_2_1/jlpt_2_1.json',
    '2_2': 'lib/assets/kanji_data/jlpt_2_2/jlpt_2_2.json',
    '2_3': 'lib/assets/kanji_data/jlpt_2_3/jlpt_2_3.json',
    '3_1': 'lib/assets/kanji_data/jlp_3_1/jlpt_3_1.json',
    '3_2': 'lib/assets/kanji_data/jlpt_3_2/jlpt_3_2.json',
    '3_3': 'lib/assets/kanji_data/jlpt_3_3/jlpt_3_3.json',
    '4_1': 'lib/assets/kanji_data/jlpt_4_1/jlpt_4_1.json',
  };

  // Load kanji data for a specific JLPT level
  Future<List<Map<String, dynamic>>> getKanjiByJlptLevel(int jlptLevel) async {
    try {
      // Get the file path for the specified JLPT level
      final filePath = _jlptFilePaths[jlptLevel];
      if (filePath == null) {
        throw Exception('Invalid JLPT level: $jlptLevel');
      }

      // Load the JSON file
      final jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert the JSON data to a list of maps
      final List<Map<String, dynamic>> kanjiList = jsonData
          .map((item) => _convertToKanjiJson(item, jlptLevel))
          .toList();

      return kanjiList;
    } catch (e) {
      throw Exception('Failed to load kanji data for JLPT level $jlptLevel: $e');
    }
  }

  // Convert the JSON data from the file to the format expected by the Kanji entity
  Map<String, dynamic> _convertToKanjiJson(dynamic item, int jlptLevel) {
    // Ensure we're working with a Map
    final Map<String, dynamic> json = Map<String, dynamic>.from(item as Map);
    
    // Extract the meaning as a list (split by semicolon if it's a single string)
    List<String> meanings = [];
    if (json['meaning'] is String) {
      meanings = (json['meaning'] as String).split(';').map((m) => m.trim()).toList();
    } else if (json['meaning'] is List) {
      meanings = List<String>.from(json['meaning']);
    }

    // Handle stroke count - ensure it's an integer
    int strokeCount = 0;
    if (json.containsKey('stroke_count')) {
      if (json['stroke_count'] is int) {
        strokeCount = json['stroke_count'];
      } else if (json['stroke_count'] is String) {
        strokeCount = int.tryParse(json['stroke_count']) ?? 0;
      }
    }
    
    // Handle grade - ensure it's an integer or null
    int? grade;
    if (json.containsKey('grade') && json['grade'] != null) {
      if (json['grade'] is int) {
        grade = json['grade'];
      } else if (json['grade'] is String) {
        grade = int.tryParse(json['grade']);
      }
    }
    
    // Create a map with the expected structure
    return {
      'kanji': json['kanji'],
      'meanings': meanings,
      'on_readings': List<String>.from(json['onyomi'] ?? []),
      'kun_readings': List<String>.from(json['kunyomi'] ?? []),
      'stroke_count': strokeCount,
      'jlpt': jlptLevel,
      'grade': grade,
      'unicode': json['unicode'],
      'heisig_en': json['heisig_en'],
      'name_readings': List<String>.from(json['name_readings'] ?? []),
      'notes': List<String>.from(json['notes'] ?? []),
    };
  }

  // Get all kanji for a specific JLPT level
  Future<List<Kanji>> getAllKanjiForJlptLevel(int jlptLevel) async {
    final jsonList = await getKanjiByJlptLevel(jlptLevel);
    return jsonList.map((json) => Kanji.fromJson(json)).toList();
  }

  // Get a subset of kanji for a specific JLPT level (for initial loading)
  Future<List<Kanji>> getInitialKanjiForJlptLevel(int jlptLevel, {int limit = 20}) async {
    final jsonList = await getKanjiByJlptLevel(jlptLevel);
    final limitedList = jsonList.take(limit).toList();
    return limitedList.map((json) => Kanji.fromJson(json)).toList();
  }
}
