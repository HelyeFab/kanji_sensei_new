import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../data/api/kanji_api_service.dart';
import '../../data/api/kanji_local_data_service.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/repositories/kanji_repository.dart';

@Injectable(as: KanjiRepository)
class KanjiRepositoryImpl implements KanjiRepository {
  final KanjiApiService _apiService;
  final KanjiLocalDataService _localDataService;
  static const String _kanjiBoxName = 'kanji_box';
  static const String _jlptLevelBoxName = 'jlpt_level_box';
  static const String _jlptFlagsBoxName = 'jlpt_flags_box';
  static const String _jlptLevelCompleteKey = 'jlpt_level_complete_';

  KanjiRepositoryImpl(this._apiService, this._localDataService);

  Future<Box<Map>> _getKanjiBox() async {
    if (!Hive.isBoxOpen(_kanjiBoxName)) {
      return await Hive.openBox<Map>(_kanjiBoxName);
    }
    return Hive.box<Map>(_kanjiBoxName);
  }

  Future<Box<List>> _getJlptLevelBox() async {
    if (!Hive.isBoxOpen(_jlptLevelBoxName)) {
      return await Hive.openBox<List>(_jlptLevelBoxName);
    }
    return Hive.box<List>(_jlptLevelBoxName);
  }
  
  Future<Box<bool>> _getJlptFlagsBox() async {
    if (!Hive.isBoxOpen(_jlptFlagsBoxName)) {
      return await Hive.openBox<bool>(_jlptFlagsBoxName);
    }
    return Hive.box<bool>(_jlptFlagsBoxName);
  }

  @override
  Future<Either<Exception, List<Kanji>>> getKanjiByLevel(int level) async {
    try {
      final kanjiList = await _apiService.getKanjiByLevel(level);
      final kanjiDetails = await Future.wait(
        kanjiList.map((kanji) => _apiService.getKanjiDetails(kanji)),
      );
      return Right(kanjiDetails.map((json) => Kanji.fromJson(json)).toList());
    } catch (e) {
      return Left(Exception('Failed to fetch kanji by level: $e'));
    }
  }

  @override
  Future<Either<Exception, Kanji>> getKanjiDetails(String kanji) async {
    try {
      // First check if we have the kanji in our cache
      final cachedResult = await getCachedKanji(kanji);
      if (cachedResult.isRight()) {
        final cachedKanji = cachedResult.getOrElse(() => null);
        if (cachedKanji != null) {
          return Right(cachedKanji);
        }
      }
      
      // If not in cache, try to find it in our local data
      try {
        // Try each JLPT level
        for (int level = 5; level >= 1; level--) {
          try {
            final kanjiList = await _localDataService.getAllKanjiForJlptLevel(level);
            final foundKanji = kanjiList.where((k) => k.character == kanji).toList();
            if (foundKanji.isNotEmpty) {
              // Cache the kanji for future use
              await cacheKanji(foundKanji.first);
              return Right(foundKanji.first);
            }
          } catch (e) {
            // Continue to the next level if this one fails
            continue;
          }
        }
      } catch (localError) {
        // If local data fails, fall back to API
        print('Failed to find kanji in local data: $localError. Falling back to API.');
      }
      
      // If not found in local data, fall back to API
      final details = await _apiService.getKanjiDetails(kanji);
      final kanjiEntity = Kanji.fromJson(details);
      
      // Cache the result
      await cacheKanji(kanjiEntity);
      
      return Right(kanjiEntity);
    } catch (e) {
      return Left(Exception('Failed to fetch kanji details: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Kanji>>> searchKanji(String query) async {
    try {
      final kanjiList = await _apiService.searchKanji(query);
      final kanjiDetails = await Future.wait(
        kanjiList.map((kanji) => _apiService.getKanjiDetails(kanji)),
      );
      return Right(kanjiDetails.map((json) => Kanji.fromJson(json)).toList());
    } catch (e) {
      return Left(Exception('Failed to search kanji: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Kanji>>> searchKanjiByJlptLevel(int jlptLevel, {int limit = 20}) async {
    try {
      // Check cache first
      final cachedResult = await getCachedJlptLevelKanji(jlptLevel);
      
      if (cachedResult.isRight()) {
        final cachedKanji = cachedResult.getOrElse(() => null);
        if (cachedKanji != null && cachedKanji.isNotEmpty) {
          // Validate that all kanji have the correct JLPT level
          final validatedKanji = cachedKanji.map((kanji) {
            if (kanji.jlptLevel != jlptLevel) {
              // Create a new kanji with the correct JLPT level
              return Kanji(
                character: kanji.character,
                onReadings: kanji.onReadings,
                kunReadings: kanji.kunReadings,
                meanings: kanji.meanings,
                strokeCount: kanji.strokeCount,
                jlptLevel: jlptLevel, // Set the correct JLPT level
                grade: kanji.grade,
                unicode: kanji.unicode,
                heisigEn: kanji.heisigEn,
                nameReadings: kanji.nameReadings,
                notes: kanji.notes,
              );
            }
            return kanji;
          }).toList();
          
          // Return from cache if available, limited to requested amount
          return Right(validatedKanji.take(limit).toList());
        }
      }
      
      try {
        // Try to get all kanji from local data first
        final allKanji = await _localDataService.getAllKanjiForJlptLevel(jlptLevel);
        
        // Cache the results
        await cacheJlptLevelKanji(jlptLevel, allKanji);
        
        // Return the limited subset
        return Right(allKanji.take(limit).toList());
      } catch (localError) {
        print('Failed to load kanji from local data: $localError. Falling back to API.');
        
        // Fallback to API if local data fails
        final kanjiDetailsList = await _apiService.searchKanjiByJlptLevel(jlptLevel, limit: limit);
        
        // Ensure all kanji have the correct JLPT level before converting to Kanji objects
        for (var details in kanjiDetailsList) {
          details['jlpt'] = jlptLevel;
        }
        
        final kanjiList = kanjiDetailsList.map((json) => Kanji.fromJson(json)).toList();
        
        // Cache the results
        await cacheJlptLevelKanji(jlptLevel, kanjiList);
        
        return Right(kanjiList);
      }
    } catch (e) {
      return Left(Exception('Failed to search kanji by JLPT level: $e'));
    }
  }
  
  @override
  Future<Either<Exception, List<Kanji>>> getInitialKanjiByJlptLevel(int jlptLevel, {int initialLimit = 20}) async {
    try {
      // Check if we have a complete cache first
      final hasCompleteCache = await hasCompleteJlptLevelCache(jlptLevel);
      
      if (hasCompleteCache.isRight() && hasCompleteCache.getOrElse(() => false)) {
        // If we have a complete cache, use it
        final cachedResult = await getCachedJlptLevelKanji(jlptLevel);
        if (cachedResult.isRight()) {
          final cachedKanji = cachedResult.getOrElse(() => null);
          if (cachedKanji != null && cachedKanji.isNotEmpty) {
            // Validate that all kanji have the correct JLPT level
            final validatedKanji = cachedKanji.map((kanji) {
              if (kanji.jlptLevel != jlptLevel) {
                // Create a new kanji with the correct JLPT level
                return Kanji(
                  character: kanji.character,
                  onReadings: kanji.onReadings,
                  kunReadings: kanji.kunReadings,
                  meanings: kanji.meanings,
                  strokeCount: kanji.strokeCount,
                  jlptLevel: jlptLevel, // Set the correct JLPT level
                  grade: kanji.grade,
                  unicode: kanji.unicode,
                  heisigEn: kanji.heisigEn,
                  nameReadings: kanji.nameReadings,
                  notes: kanji.notes,
                );
              }
              return kanji;
            }).toList();
            
            return Right(validatedKanji.take(initialLimit).toList());
          }
        }
      }
      
      try {
        // Use local data service to get kanji for the specified JLPT level
        final kanjiList = await _localDataService.getInitialKanjiForJlptLevel(jlptLevel, limit: initialLimit);
        
        // Cache the results
        await cacheJlptLevelKanji(jlptLevel, kanjiList);
        
        return Right(kanjiList);
      } catch (localError) {
        print('Failed to load kanji from local data: $localError. Falling back to API.');
        
        // Fallback to API if local data fails
        final kanjiDetailsList = await _apiService.searchKanjiByJlptLevel(jlptLevel, limit: initialLimit);
        
        // Ensure all kanji have the correct JLPT level before converting to Kanji objects
        for (var details in kanjiDetailsList) {
          details['jlpt'] = jlptLevel;
        }
        
        return Right(kanjiDetailsList.map((json) => Kanji.fromJson(json)).toList());
      }
    } catch (e) {
      return Left(Exception('Failed to get initial kanji by JLPT level: $e'));
    }
  }
  
  @override
  Future<Either<Exception, List<Kanji>>> getAllKanjiByJlptLevel(int jlptLevel) async {
    try {
      // Check if we have a complete cache first
      final hasCompleteCache = await hasCompleteJlptLevelCache(jlptLevel);
      
      if (hasCompleteCache.isRight() && hasCompleteCache.getOrElse(() => false)) {
        // If we have a complete cache, use it
        final cachedResult = await getCachedJlptLevelKanji(jlptLevel);
        if (cachedResult.isRight()) {
          final cachedKanji = cachedResult.getOrElse(() => null);
          if (cachedKanji != null && cachedKanji.isNotEmpty) {
            // Validate that all kanji have the correct JLPT level
            final validatedKanji = cachedKanji.map((kanji) {
              if (kanji.jlptLevel != jlptLevel) {
                // Create a new kanji with the correct JLPT level
                return Kanji(
                  character: kanji.character,
                  onReadings: kanji.onReadings,
                  kunReadings: kanji.kunReadings,
                  meanings: kanji.meanings,
                  strokeCount: kanji.strokeCount,
                  jlptLevel: jlptLevel, // Set the correct JLPT level
                  grade: kanji.grade,
                  unicode: kanji.unicode,
                  heisigEn: kanji.heisigEn,
                  nameReadings: kanji.nameReadings,
                  notes: kanji.notes,
                );
              }
              return kanji;
            }).toList();
            
            return Right(validatedKanji);
          }
        }
      }
      
      try {
        // Use local data service to get all kanji for the specified JLPT level
        final kanjiList = await _localDataService.getAllKanjiForJlptLevel(jlptLevel);
        
        // Cache the complete list
        await cacheJlptLevelKanji(jlptLevel, kanjiList);
        
        // Mark this JLPT level as completely cached
        final flagsBox = await _getJlptFlagsBox();
        await flagsBox.put(_jlptLevelCompleteKey + jlptLevel.toString(), true);
        
        return Right(kanjiList);
      } catch (localError) {
        print('Failed to load kanji from local data: $localError. Falling back to API.');
        
        // Fallback to API if local data fails
        final kanjiDetailsList = await _apiService.getAllKanjiByJlptLevel(jlptLevel);
        
        // Ensure all kanji have the correct JLPT level before converting to Kanji objects
        for (var details in kanjiDetailsList) {
          details['jlpt'] = jlptLevel;
        }
        
        final kanjiList = kanjiDetailsList.map((json) => Kanji.fromJson(json)).toList();
        
        // Cache the complete list
        await cacheJlptLevelKanji(jlptLevel, kanjiList);
        
        // Mark this JLPT level as completely cached
        final flagsBox = await _getJlptFlagsBox();
        await flagsBox.put(_jlptLevelCompleteKey + jlptLevel.toString(), true);
        
        return Right(kanjiList);
      }
    } catch (e) {
      return Left(Exception('Failed to get all kanji by JLPT level: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> cacheKanji(Kanji kanji) async {
    try {
      final box = await _getKanjiBox();
      await box.put(kanji.character, kanji.toJson());
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to cache kanji: $e'));
    }
  }

  @override
  Future<Either<Exception, Kanji?>> getCachedKanji(String kanji) async {
    try {
      final box = await _getKanjiBox();
      final cachedData = box.get(kanji);
      
      if (cachedData != null) {
        return Right(Kanji.fromJson(Map<String, dynamic>.from(cachedData)));
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to get cached kanji: $e'));
    }
  }
  
  @override
  Future<Either<Exception, void>> cacheJlptLevelKanji(int jlptLevel, List<Kanji> kanjiList) async {
    try {
      final box = await _getJlptLevelBox();
      
      // Convert Kanji objects to JSON
      final jsonList = kanjiList.map((kanji) => kanji.toJson()).toList();
      
      // Store in Hive
      await box.put('jlpt_$jlptLevel', jsonList);
      
      // Also cache individual kanji
      for (final kanji in kanjiList) {
        await cacheKanji(kanji);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to cache JLPT level kanji: $e'));
    }
  }
  
  @override
  Future<Either<Exception, List<Kanji>?>> getCachedJlptLevelKanji(int jlptLevel) async {
    try {
      final box = await _getJlptLevelBox();
      final cachedData = box.get('jlpt_$jlptLevel');
      
      if (cachedData != null) {
        // Convert JSON back to Kanji objects
        final List<Kanji> kanjiList = [];
        
        for (var json in cachedData) {
          final Map<String, dynamic> kanjiJson = Map<String, dynamic>.from(json as Map);
          
          // Ensure the JLPT level is correct
          kanjiJson['jlpt'] = jlptLevel;
          
          kanjiList.add(Kanji.fromJson(kanjiJson));
        }
        
        return Right(kanjiList);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to get cached JLPT level kanji: $e'));
    }
  }
  
  @override
  Future<Either<Exception, bool>> hasCompleteJlptLevelCache(int jlptLevel) async {
    try {
      final flagsBox = await _getJlptFlagsBox();
      final isComplete = flagsBox.get(_jlptLevelCompleteKey + jlptLevel.toString()) ?? false;
      return Right(isComplete);
    } catch (e) {
      return Left(Exception('Failed to check JLPT level cache status: $e'));
    }
  }
}
