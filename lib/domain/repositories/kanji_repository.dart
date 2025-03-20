import 'package:dartz/dartz.dart';
import '../entities/kanji.dart';

abstract class KanjiRepository {
  Future<Either<Exception, List<Kanji>>> getKanjiByLevel(int level);
  Future<Either<Exception, Kanji>> getKanjiDetails(String kanji);
  Future<Either<Exception, List<Kanji>>> searchKanji(String query);
  
  // Original method - kept for backward compatibility
  Future<Either<Exception, List<Kanji>>> searchKanjiByJlptLevel(int jlptLevel, {int limit = 20});
  
  // New methods for improved JLPT kanji loading
  Future<Either<Exception, List<Kanji>>> getInitialKanjiByJlptLevel(int jlptLevel, {int initialLimit = 20});
  Future<Either<Exception, List<Kanji>>> getAllKanjiByJlptLevel(int jlptLevel);
  
  // Caching methods
  Future<Either<Exception, void>> cacheKanji(Kanji kanji);
  Future<Either<Exception, Kanji?>> getCachedKanji(String kanji);
  Future<Either<Exception, void>> cacheJlptLevelKanji(int jlptLevel, List<Kanji> kanjiList);
  Future<Either<Exception, List<Kanji>?>> getCachedJlptLevelKanji(int jlptLevel);
  Future<Either<Exception, bool>> hasCompleteJlptLevelCache(int jlptLevel);
}
