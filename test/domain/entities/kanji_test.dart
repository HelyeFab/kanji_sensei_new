import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_sensei/domain/entities/kanji.dart';

void main() {
  group('Kanji Entity Tests', () {
    test('Kanji entity can be created', () {
      final kanji = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5,
      );
      expect(kanji, isA<Kanji>());
      expect(kanji.character, '日');
      expect(kanji.onReadings, ['ニチ']);
      expect(kanji.kunReadings, ['ひ']);
      expect(kanji.meanings, ['sun', 'day']);
      expect(kanji.strokeCount, 4);
      expect(kanji.jlptLevel, 5);
    });

    test('Kanji entity props are correct', () {
      final kanji1 = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5,
      );
      final kanji2 = Kanji(
        character: '日',
        onReadings: ['ニチ'],
        kunReadings: ['ひ'],
        meanings: ['sun', 'day'],
        strokeCount: 4,
        jlptLevel: 5,
      );
      expect(kanji1.props, [
        kanji1.character,
        kanji1.onReadings,
        kanji1.kunReadings,
        kanji1.meanings,
        kanji1.strokeCount,
        kanji1.jlptLevel,
      ]);
      expect(kanji1 == kanji2, true);
    });
  });
}
