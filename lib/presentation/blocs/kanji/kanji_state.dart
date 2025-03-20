import 'package:equatable/equatable.dart';
import '../../../domain/entities/kanji.dart';

enum KanjiStatus { initial, loading, loadingMore, success, error }

class KanjiState extends Equatable {
  final KanjiStatus status;
  final List<Kanji> kanjiList;
  final String? errorMessage;
  final Kanji? selectedKanji;
  final int currentPage;
  final int itemsPerPage;
  final bool isAllLoaded;
  final int? totalKanjiCount;
  final int jlptLevel;

  const KanjiState({
    this.status = KanjiStatus.initial,
    this.kanjiList = const [],
    this.errorMessage,
    this.selectedKanji,
    this.currentPage = 0,
    this.itemsPerPage = 20,
    this.isAllLoaded = false,
    this.totalKanjiCount,
    this.jlptLevel = 0,
  });

  KanjiState copyWith({
    KanjiStatus? status,
    List<Kanji>? kanjiList,
    String? errorMessage,
    Kanji? selectedKanji,
    int? currentPage,
    int? itemsPerPage,
    bool? isAllLoaded,
    int? totalKanjiCount,
    int? jlptLevel,
  }) {
    return KanjiState(
      status: status ?? this.status,
      kanjiList: kanjiList ?? this.kanjiList,
      errorMessage: errorMessage,
      selectedKanji: selectedKanji ?? this.selectedKanji,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      isAllLoaded: isAllLoaded ?? this.isAllLoaded,
      totalKanjiCount: totalKanjiCount ?? this.totalKanjiCount,
      jlptLevel: jlptLevel ?? this.jlptLevel,
    );
  }

  List<Kanji> get currentPageKanji {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > kanjiList.length
        ? kanjiList.length
        : startIndex + itemsPerPage;

    if (startIndex >= kanjiList.length) {
      return [];
    }

    return kanjiList.sublist(startIndex, endIndex);
  }

  bool get hasNextPage {
    return (currentPage + 1) * itemsPerPage < kanjiList.length;
  }

  int get availablePages {
    return (kanjiList.length / itemsPerPage).ceil();
  }

  bool get hasPreviousPage {
    return currentPage > 0;
  }

  @override
  List<Object?> get props => [
        status,
        kanjiList,
        errorMessage,
        selectedKanji,
        currentPage,
        itemsPerPage,
        isAllLoaded,
        totalKanjiCount,
        jlptLevel,
      ];
}
