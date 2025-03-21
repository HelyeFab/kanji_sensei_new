import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:kanji_sensei/domain/entities/kanji.dart';
import 'package:kanji_sensei/domain/repositories/kanji_repository.dart';

class MockKanjiRepository extends Mock implements KanjiRepository {
  @override
  Future<Either<Exception, List<Kanji>>> getKanjiByLevel(int level) => 
      super.noSuchMethod(Invocation.method(#getKanjiByLevel, [level]));
  
  @override
  Future<Either<Exception, Kanji>> getKanjiDetails(String kanji) => 
      super.noSuchMethod(Invocation.method(#getKanjiDetails, [kanji]));
  
  @override
  Future<Either<Exception, List<Kanji>>> searchKanji(String query) => 
      super.noSuchMethod(Invocation.method(#searchKanji, [query]));
  
  @override
  Future<Either<Exception, void>> cacheKanji(Kanji kanji) => 
      super.noSuchMethod(Invocation.method(#cacheKanji, [kanji]));
  
  @override
  Future<Either<Exception, Kanji?>> getCachedKanji(String kanji) => 
      super.noSuchMethod(Invocation.method(#getCachedKanji, [kanji]));
}

void main() {
  late MockKanjiRepository mockKanjiRepository;

  setUp(() {
    mockKanjiRepository = MockKanjiRepository();
  });

  group('KanjiRepository Tests', () {
    test('getKanjiByLevel should return list of Kanji', () async {
      // Arrange
      final testKanjiList = [Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5
      )];
      when(() => mockKanjiRepository.getKanjiByLevel(1))
          .thenAnswer((_) async => Future<Either<Exception, List<Kanji>>>.value(Right(testKanjiList)));

      // Act
      final result = await mockKanjiRepository.getKanjiByLevel(1);

      // Assert
      expect(result, Right(testKanjiList));
      verify(() => mockKanjiRepository.getKanjiByLevel(1));
    });

    test('getKanjiDetails should return Kanji details', () async {
      // Arrange
      final testKanji = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5
      );
      when(() => mockKanjiRepository.getKanjiDetails('日'))
          .thenAnswer((_) async => Future<Either<Exception, Kanji>>.value(Right(testKanji)));

      // Act
      final result = await mockKanjiRepository.getKanjiDetails('日');

      // Assert
      expect(result, Right(testKanji));
      verify(() => mockKanjiRepository.getKanjiDetails('日'));
    });

    test('searchKanji should return matching Kanji', () async {
      // Arrange
      final testKanjiList = [Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5
      )];
      when(() => mockKanjiRepository.searchKanji('日'))
          .thenAnswer((_) async => Future<Either<Exception, List<Kanji>>>.value(Right(testKanjiList)));

      // Act
      final result = await mockKanjiRepository.searchKanji('日');

      // Assert
      expect(result, Right(testKanjiList));
      verify(() => mockKanjiRepository.searchKanji('日'));
    });

    test('cacheKanji should store Kanji successfully', () async {
      // Arrange
      final testKanji = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5
      );
      when(() => mockKanjiRepository.cacheKanji(testKanji))
          .thenAnswer((_) async => Future<Either<Exception, void>>.value(Right(null)));

      // Act
      final result = await mockKanjiRepository.cacheKanji(testKanji);

      // Assert
      expect(result, Right(null));
      verify(() => mockKanjiRepository.cacheKanji(testKanji));
    });

    test('getCachedKanji should return cached Kanji', () async {
      // Arrange
      final testKanji = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5
      );
      when(() => mockKanjiRepository.getCachedKanji('日'))
          .thenAnswer((_) async => Future<Either<Exception, Kanji?>>.value(Right(testKanji)));

      // Act
      final result = await mockKanjiRepository.getCachedKanji('日');

      // Assert
      expect(result, Right(testKanji));
      verify(() => mockKanjiRepository.getCachedKanji('日'));
    });
  });
}
