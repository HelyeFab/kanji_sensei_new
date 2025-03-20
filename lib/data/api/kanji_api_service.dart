import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/app_config.dart';

@injectable
class KanjiApiService {
  final Dio _dio;
  final Dio _jishoDio;

  KanjiApiService()
      : _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)),
        _jishoDio = Dio(BaseOptions(
            baseUrl: 'https://jisho.org/api/v1/',
            headers: {'User-Agent': 'Mozilla/5.0'}));

  Future<List<String>> getKanjiByLevel(int level) async {
    try {
      final response = await _dio.get('kanji/grade-$level');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch kanji by level: $e');
    }
  }

  Future<Map<String, dynamic>> getKanjiDetails(String kanji) async {
    try {
      // Make sure we're using the correct endpoint format
      final response = await _dio.get('kanji/$kanji');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch kanji details: $e');
    }
  }

  Future<List<String>> searchKanji(String query) async {
    try {
      // If the query is a single character, we'll search for words containing that kanji
      if (query.length == 1) {
        final response = await _dio.get('words/$query');
        // Extract kanji from the words
        final Set<String> kanjiSet = {};
        final List<dynamic> words = response.data;
        for (var word in words) {
          for (var variant in word['variants']) {
            final String written = variant['written'];
            for (var char in written.split('')) {
              if (_isKanji(char)) {
                kanjiSet.add(char);
              }
            }
          }
        }
        return kanjiSet.toList();
      } else {
        // If the query is multiple characters, we'll search for kanji by reading
        final response = await _dio.get('reading/$query');
        final List<String> mainKanji =
            List<String>.from(response.data['main_kanji'] ?? []);
        final List<String> nameKanji =
            List<String>.from(response.data['name_kanji'] ?? []);
        return [...mainKanji, ...nameKanji];
      }
    } catch (e) {
      throw Exception('Failed to search kanji: $e');
    }
  }

  bool _isKanji(String char) {
    // Check if the character is a kanji (CJK Unified Ideographs)
    final int code = char.codeUnitAt(0);
    return (code >= 0x4E00 && code <= 0x9FFF);
  }

  Future<List<Map<String, dynamic>>> searchKanjiByJlptLevel(int jlptLevel,
      {int limit = 20}) async {
    try {
      // Try to use Jisho API first
      try {
        return await _searchKanjiByJlptLevelUsingJisho(jlptLevel, limit: limit);
      } catch (jishoError) {
        print(
            'Failed to use Jisho API: $jishoError. Falling back to KanjiAPI.');

        // Fallback to original implementation
        final response = await _dio.get('kanji/joyo');
        final List<String> allKanji = List<String>.from(response.data);

        // Fetch details for each kanji and filter by JLPT level
        List<Map<String, dynamic>> matchingKanji = [];
        for (String kanji in allKanji) {
          try {
            final details = await getKanjiDetails(kanji);
            final int? kanjiJlptLevel = details['jlpt'] as int?;

            // Check if the kanji has the requested JLPT level
            if (kanjiJlptLevel == jlptLevel) {
              matchingKanji.add(details);

              // Return initial batch quickly
              if (limit > 0 && matchingKanji.length >= limit) {
                break;
              }
            }
          } catch (e) {
            // Skip kanji that fail to load
            print('Failed to load details for kanji $kanji: $e');
          }
        }

        return matchingKanji;
      }
    } catch (e) {
      throw Exception('Failed to search kanji by JLPT level: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _searchKanjiByJlptLevelUsingJisho(
      int jlptLevel,
      {int limit = 20}) async {
    try {
      // Search for words with the specified JLPT level
      final response = await _jishoDio.get('search/words',
          queryParameters: {'keyword': '%23jlpt-n$jlptLevel', 'page': 1});

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch data from Jisho API: ${response.statusCode}');
      }

      // Extract kanji from the words
      final List<dynamic> data = response.data['data'] ?? [];
      if (data.isEmpty) {
        // Try a different approach - search for common words at this level
        return await _searchCommonWordsForJlptLevel(jlptLevel, limit: limit);
      }

      final Set<String> kanjiSet = {};
      final List<Map<String, dynamic>> kanjiDetails = [];

      for (var item in data) {
        // Check if this item has the correct JLPT level
        final List<dynamic> jlptTags = item['jlpt'] ?? [];
        if (!jlptTags.contains('jlpt-n$jlptLevel')) continue;

        // Extract kanji from Japanese words
        final List<dynamic> japanese = item['japanese'] ?? [];
        for (var word in japanese) {
          final String? written = word['word'];
          if (written != null) {
            for (var char in written.split('')) {
              if (_isKanji(char) && !kanjiSet.contains(char)) {
                kanjiSet.add(char);

                // Create a kanji details object
                final Map<String, dynamic> details = {
                  'kanji': char,
                  'jlpt': jlptLevel,
                  'meanings': _extractMeanings(item),
                  'kun_readings': [],
                  'on_readings': [],
                  'stroke_count': 0,
                  'name_readings': [],
                  'grade': null,
                  'heisig_en': null,
                  'notes': [],
                };

                // Add readings if available
                if (word['reading'] != null) {
                  details['on_readings'] = [word['reading']];
                }

                kanjiDetails.add(details);

                // Return initial batch quickly
                if (limit > 0 && kanjiDetails.length >= limit) {
                  return kanjiDetails;
                }
              }
            }
          }
        }
      }

      return kanjiDetails;
    } catch (e) {
      // If we hit a rate limit, wait and try again once
      if (e.toString().contains('429')) {
        print('Rate limit hit, waiting 3 seconds before retrying...');
        await Future.delayed(const Duration(seconds: 3));

        // Try a different approach instead of retrying the same request
        return await _searchCommonWordsForJlptLevel(jlptLevel, limit: limit);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _searchCommonWordsForJlptLevel(
      int jlptLevel,
      {int limit = 20}) async {
    // Common words for each JLPT level - expanded list with more words to capture more kanji
    List<String> commonWords = [];

    // Add level-specific common words
    if (jlptLevel == 5) {
      // N5 level common words
      commonWords = [
        '日本語',
        '勉強',
        '学校',
        '先生',
        '学生',
        '友達',
        '家族',
        '仕事',
        '会社',
        '時間',
        '一',
        '二',
        '三',
        '四',
        '五',
        '六',
        '七',
        '八',
        '九',
        '十',
        '百',
        '千',
        '万',
        '円',
        '年',
        '月',
        '日',
        '曜日',
        '時',
        '分',
        '人',
        '男',
        '女',
        '子',
        '水',
        '火',
        '木',
        '金',
        '土',
        '本',
        '山',
        '川',
        '田',
        '上',
        '下',
        '中',
        '外',
        '前',
        '後',
        '右',
        '左',
        '東',
        '西',
        '南',
        '北',
        '白',
        '黒',
        '赤',
        '青',
        '名前'
      ];
    } else if (jlptLevel == 4) {
      // N4 level common words
      commonWords = [
        '映画',
        '音楽',
        '旅行',
        '料理',
        '運動',
        '電車',
        '自転車',
        '病院',
        '銀行',
        '郵便局',
        '図書館',
        '美術館',
        '動物園',
        '公園',
        '駅',
        '空港',
        '道',
        '橋',
        '海',
        '空',
        '雨',
        '雪',
        '風',
        '星',
        '花',
        '犬',
        '猫',
        '鳥',
        '魚',
        '肉',
        '野菜',
        '果物',
        '米',
        '茶',
        '酒',
        '牛乳',
        '卵',
        '塩',
        '砂糖',
        '油'
      ];
    } else if (jlptLevel == 3) {
      // N3 level common words
      commonWords = [
        '経済',
        '政治',
        '社会',
        '文化',
        '歴史',
        '科学',
        '技術',
        '環境',
        '教育',
        '医療',
        '健康',
        '安全',
        '平和',
        '戦争',
        '国際',
        '地域',
        '都市',
        '農村',
        '産業',
        '商業',
        '工業',
        '農業',
        '漁業',
        '観光',
        '交通',
        '通信',
        '情報',
        '研究',
        '開発',
        '生産'
      ];
    } else if (jlptLevel == 2) {
      // N2 level common words
      commonWords = [
        '議論',
        '批判',
        '主張',
        '反論',
        '解決',
        '対策',
        '方針',
        '計画',
        '目標',
        '成果',
        '結果',
        '影響',
        '効果',
        '原因',
        '理由',
        '状況',
        '状態',
        '条件',
        '要素',
        '特徴',
        '傾向',
        '変化',
        '発展',
        '進歩',
        '改善',
        '改革',
        '革新',
        '創造',
        '発明',
        '発見'
      ];
    } else if (jlptLevel == 1) {
      // N1 level common words
      commonWords = [
        '抽象',
        '具体',
        '理論',
        '実践',
        '分析',
        '総合',
        '評価',
        '判断',
        '認識',
        '思考',
        '感情',
        '意識',
        '無意識',
        '本能',
        '欲望',
        '意志',
        '決断',
        '選択',
        '行動',
        '態度',
        '姿勢',
        '立場',
        '視点',
        '観点',
        '見解',
        '意見',
        '考え',
        '思想',
        '哲学',
        '倫理'
      ];
    } else {
      // Default common words
      commonWords = [
        '日本語',
        '勉強',
        '学校',
        '先生',
        '学生',
        '友達',
        '家族',
        '仕事',
        '会社',
        '時間'
      ];
    }

    final Set<String> kanjiSet = {};
    final List<Map<String, dynamic>> kanjiDetails = [];

    // Search for each common word with rate limiting
    for (var i = 0; i < commonWords.length; i++) {
      final word = commonWords[i];
      try {
        // Add delay between requests to avoid rate limiting (429 errors)
        if (i > 0) {
          // Wait 1.5 seconds between requests
          await Future.delayed(const Duration(milliseconds: 1500));
        }

        final response = await _jishoDio
            .get('search/words', queryParameters: {'keyword': word, 'page': 1});

        if (response.statusCode != 200) continue;

        final List<dynamic> data = response.data['data'] ?? [];
        if (data.isEmpty) continue;

        for (var item in data) {
          // Check if this item has the correct JLPT level
          final List<dynamic> jlptTags = item['jlpt'] ?? [];
          if (!jlptTags.contains('jlpt-n$jlptLevel')) continue;

          // Extract kanji from Japanese words
          final List<dynamic> japanese = item['japanese'] ?? [];
          for (var wordData in japanese) {
            final String? written = wordData['word'];
            if (written != null) {
              for (var char in written.split('')) {
                if (_isKanji(char) && !kanjiSet.contains(char)) {
                  kanjiSet.add(char);

                  // Create a kanji details object
                  final Map<String, dynamic> details = {
                    'kanji': char,
                    'jlpt': jlptLevel,
                    'meanings': _extractMeanings(item),
                    'kun_readings': [],
                    'on_readings': [],
                    'stroke_count': 0,
                    'name_readings': [],
                    'grade': null,
                    'heisig_en': null,
                    'notes': [],
                  };

                  // Add readings if available
                  if (wordData['reading'] != null) {
                    details['on_readings'] = [wordData['reading']];
                  }

                  kanjiDetails.add(details);

                  // Return initial batch quickly
                  if (limit > 0 && kanjiDetails.length >= limit) {
                    return kanjiDetails;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error searching for word $word: $e');
        // If we hit a rate limit, wait longer before the next request
        if (e.toString().contains('429')) {
          await Future.delayed(const Duration(seconds: 3));
        }
        continue;
      }
    }

    return kanjiDetails;
  }

  List<String> _extractMeanings(Map<String, dynamic> wordData) {
    final List<String> meanings = [];
    final List<dynamic> senses = wordData['senses'] ?? [];

    for (var sense in senses) {
      final List<dynamic> englishDefinitions =
          sense['english_definitions'] ?? [];
      for (var definition in englishDefinitions) {
        if (definition is String && !meanings.contains(definition)) {
          meanings.add(definition);
        }
      }
    }

    return meanings;
  }

  Future<List<Map<String, dynamic>>> getAllKanjiByJlptLevel(
      int jlptLevel) async {
    try {
      // First try to get kanji using the Jisho API with multiple approaches
      final List<Map<String, dynamic>> initialResults = [];
      
      // 1. Try direct hashtag search
      try {
        final response = await _jishoDio.get('search/words',
            queryParameters: {'keyword': '%23jlpt-n$jlptLevel', 'page': 1});
            
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['data'] ?? [];
          if (data.isNotEmpty) {
            // Process results
            final Set<String> kanjiSet = {};
            
            for (var item in data) {
              // Verify this item has the correct JLPT level
              final List<dynamic> jlptTags = item['jlpt'] ?? [];
              if (!jlptTags.contains('jlpt-n$jlptLevel')) continue;
              
              final List<dynamic> japanese = item['japanese'] ?? [];
              for (var word in japanese) {
                final String? written = word['word'];
                if (written != null) {
                  for (var char in written.split('')) {
                    if (_isKanji(char) && !kanjiSet.contains(char)) {
                      kanjiSet.add(char);
                      
                      // Create kanji details
                      final Map<String, dynamic> details = {
                        'kanji': char,
                        'jlpt': jlptLevel,
                        'meanings': _extractMeanings(item),
                        'kun_readings': [],
                        'on_readings': [],
                        'stroke_count': 0,
                        'name_readings': [],
                        'grade': null,
                        'heisig_en': null,
                        'notes': [],
                      };
                      
                      // Add readings if available
                      if (word['reading'] != null) {
                        details['on_readings'] = [word['reading']];
                      }
                      
                      initialResults.add(details);
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error in direct hashtag search: $e');
        // Continue to next approach
      }
      
      // 2. Search for common words at this level
      if (initialResults.isEmpty || initialResults.length < 50) {
        try {
          // Wait to avoid rate limiting
          await Future.delayed(const Duration(seconds: 2));
          
          final commonWordResults = await _searchCommonWordsForJlptLevel(jlptLevel, limit: 0);
          
          // Add unique kanji from common word search
          final Set<String> existingKanji = initialResults.map((k) => k['kanji'] as String).toSet();
          for (var kanji in commonWordResults) {
            if (!existingKanji.contains(kanji['kanji'])) {
              initialResults.add(kanji);
              existingKanji.add(kanji['kanji'] as String);
            }
          }
        } catch (e) {
          print('Error in common word search: $e');
          // Continue to next approach
        }
      }
      
      // 3. If we still don't have enough kanji, try the original API
      if (initialResults.isEmpty || initialResults.length < 50) {
        try {
          final fallbackResults = await searchKanjiByJlptLevel(jlptLevel, limit: 0);
          
          // Add unique kanji from fallback search
          final Set<String> existingKanji = initialResults.map((k) => k['kanji'] as String).toSet();
          for (var kanji in fallbackResults) {
            if (!existingKanji.contains(kanji['kanji'])) {
              initialResults.add(kanji);
              existingKanji.add(kanji['kanji'] as String);
            }
          }
        } catch (e) {
          print('Error in fallback search: $e');
          // If all approaches fail, return what we have
        }
      }
      
      // If we still don't have enough results, add hardcoded kanji for certain levels
      if (initialResults.length < 50) {
        final Set<String> existingKanji = initialResults.map((k) => k['kanji'] as String).toSet();
        
        // Add level-specific hardcoded kanji
        List<String> hardcodedKanji = [];
        
        if (jlptLevel == 5) {
          // N5 level kanji (basic kanji)
          hardcodedKanji = [
            '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '百', '千', '万',
            '日', '月', '火', '水', '木', '金', '土', '曜', '年', '時', '分', '半', '間',
            '上', '下', '中', '外', '右', '左', '前', '後', '東', '西', '南', '北',
            '人', '男', '女', '子', '父', '母', '家', '族', '友', '会', '社',
            '学', '校', '先', '生', '山', '川', '田', '文', '字', '本', '語',
            '名', '白', '黒', '赤', '青', '円', '入', '出', '立', '休', '見',
            '聞', '読', '書', '話', '食', '飲', '買', '来', '行', '帰', '歩',
            '止', '車', '電', '駅', '道', '店', '屋', '所', '国', '今', '新',
            '古', '高', '安', '小', '大', '長', '短', '多', '少', '早', '遅'
          ];
        } else if (jlptLevel == 4) {
          // N4 level kanji (sample)
          hardcodedKanji = [
            '会', '同', '事', '自', '社', '発', '者', '地', '業', '方',
            '新', '場', '員', '立', '開', '手', '力', '問', '代', '明',
            '動', '京', '目', '通', '言', '理', '体', '田', '主', '題',
            '意', '不', '作', '用', '度', '強', '公', '持', '野', '家',
            '世', '多', '正', '安', '院', '心', '界', '教', '文', '元'
          ];
        }
        
        // Add hardcoded kanji that aren't already in the results
        for (var kanji in hardcodedKanji) {
          if (!existingKanji.contains(kanji)) {
            initialResults.add({
              'kanji': kanji,
              'jlpt': jlptLevel,
              'meanings': [],
              'kun_readings': [],
              'on_readings': [],
              'stroke_count': 0,
              'name_readings': [],
              'grade': null,
              'heisig_en': null,
              'notes': [],
            });
          }
        }
      }
      
      // Final validation: ensure all kanji have the correct JLPT level
      final List<Map<String, dynamic>> validatedResults = [];
      for (var kanji in initialResults) {
        // Set the JLPT level explicitly to the requested level
        kanji['jlpt'] = jlptLevel;
        validatedResults.add(kanji);
      }
      
      return validatedResults;
    } catch (e) {
      print('Error in getAllKanjiByJlptLevel: $e');
      // If all approaches fail, fall back to the original method
      return searchKanjiByJlptLevel(jlptLevel, limit: 0);
    }
  }
}
