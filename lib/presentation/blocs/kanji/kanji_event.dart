import 'package:equatable/equatable.dart';

abstract class KanjiEvent extends Equatable {
  const KanjiEvent();

  @override
  List<Object?> get props => [];
}

class LoadKanjiByLevel extends KanjiEvent {
  final int level;

  const LoadKanjiByLevel(this.level);

  @override
  List<Object?> get props => [level];
}

class SearchKanji extends KanjiEvent {
  final String query;

  const SearchKanji(this.query);

  @override
  List<Object?> get props => [query];
}

// Deprecated - kept for backward compatibility
class SearchKanjiByJlptLevel extends KanjiEvent {
  final int jlptLevel;
  final int limit;

  const SearchKanjiByJlptLevel(this.jlptLevel, {this.limit = 20});

  @override
  List<Object?> get props => [jlptLevel, limit];
}

// New event for initial quick loading of JLPT kanji
class LoadInitialKanjiByJlptLevel extends KanjiEvent {
  final int jlptLevel;
  final int initialLimit;

  const LoadInitialKanjiByJlptLevel(this.jlptLevel, {this.initialLimit = 20});

  @override
  List<Object?> get props => [jlptLevel, initialLimit];
}

// New event for background loading of remaining JLPT kanji
class LoadRemainingKanjiByJlptLevel extends KanjiEvent {
  final int jlptLevel;

  const LoadRemainingKanjiByJlptLevel(this.jlptLevel);

  @override
  List<Object?> get props => [jlptLevel];
}

// Event for pagination
class ChangePage extends KanjiEvent {
  final int page;

  const ChangePage(this.page);

  @override
  List<Object?> get props => [page];
}

class SelectKanji extends KanjiEvent {
  final String? kanji;

  const SelectKanji(this.kanji);

  @override
  List<Object?> get props => [kanji];
}

class ClearError extends KanjiEvent {}

class ClearSelectedKanji extends KanjiEvent {}
