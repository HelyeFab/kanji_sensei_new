import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/kanji.dart';
import '../../../domain/repositories/kanji_repository.dart';
import 'kanji_event.dart';
import 'kanji_state.dart';

// Internal event for updating kanji list from background loading
class _UpdateKanjiList extends KanjiEvent {
  final List<Kanji> kanjiList;
  final bool isAllLoaded;
  
  const _UpdateKanjiList(this.kanjiList, {this.isAllLoaded = false});
  
  @override
  List<Object?> get props => [kanjiList, isAllLoaded];
}

class KanjiBloc extends Bloc<KanjiEvent, KanjiState> {
  final KanjiRepository _repository;
  
  // Keep track of background loading tasks
  StreamSubscription? _backgroundLoadingSubscription;

  KanjiBloc(this._repository) : super(const KanjiState()) {
    on<LoadKanjiByLevel>(_onLoadKanjiByLevel);
    on<SearchKanji>(_onSearchKanji);
    on<SearchKanjiByJlptLevel>(_onSearchKanjiByJlptLevel);
    on<LoadInitialKanjiByJlptLevel>(_onLoadInitialKanjiByJlptLevel);
    on<LoadRemainingKanjiByJlptLevel>(_onLoadRemainingKanjiByJlptLevel);
    on<ChangePage>(_onChangePage);
    on<SelectKanji>(_onSelectKanji);
    on<ClearError>(_onClearError);
    on<_UpdateKanjiList>(_onUpdateKanjiList);
  }
  
  @override
  Future<void> close() {
    _backgroundLoadingSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadKanjiByLevel(
    LoadKanjiByLevel event,
    Emitter<KanjiState> emit,
  ) async {
    emit(state.copyWith(status: KanjiStatus.loading, selectedKanji: null));
    final result = await _repository.getKanjiByLevel(event.level);
    result.fold(
      (failure) => emit(state.copyWith(
        status: KanjiStatus.error,
        errorMessage: failure.toString(),
        selectedKanji: null,
      )),
      (kanjiList) => emit(state.copyWith(
        status: KanjiStatus.success,
        kanjiList: kanjiList,
        selectedKanji: null,
      )),
    );
  }

  Future<void> _onSearchKanji(
    SearchKanji event,
    Emitter<KanjiState> emit,
  ) async {
    emit(state.copyWith(status: KanjiStatus.loading, selectedKanji: null));
    final result = await _repository.searchKanji(event.query);
    result.fold(
      (failure) => emit(state.copyWith(
        status: KanjiStatus.error,
        errorMessage: failure.toString(),
        selectedKanji: null,
      )),
      (kanjiList) => emit(state.copyWith(
        status: KanjiStatus.success,
        kanjiList: kanjiList,
        selectedKanji: null,
      )),
    );
  }

  // Legacy method - kept for backward compatibility
  Future<void> _onSearchKanjiByJlptLevel(
    SearchKanjiByJlptLevel event,
    Emitter<KanjiState> emit,
  ) async {
    // Delegate to the new implementation
    add(LoadInitialKanjiByJlptLevel(event.jlptLevel, initialLimit: event.limit));
  }
  
  // Step 1: Load initial batch of kanji quickly
  Future<void> _onLoadInitialKanjiByJlptLevel(
    LoadInitialKanjiByJlptLevel event,
    Emitter<KanjiState> emit,
  ) async {
    // Reset pagination and clear previous results
    emit(state.copyWith(
      status: KanjiStatus.loading, 
      selectedKanji: null,
      currentPage: 0,
      isAllLoaded: false,
      kanjiList: const [], // Clear previous results
      jlptLevel: event.jlptLevel, // Store the selected JLPT level
    ));
    
    // Check if we have a complete cache first
    final hasCompleteCache = await _repository.hasCompleteJlptLevelCache(event.jlptLevel);
    
    if (hasCompleteCache.isRight() && hasCompleteCache.getOrElse(() => false)) {
      // If we have a complete cache, get all kanji at once
      final cachedResult = await _repository.getCachedJlptLevelKanji(event.jlptLevel);
      if (cachedResult.isRight()) {
        final cachedKanji = cachedResult.getOrElse(() => null);
        if (cachedKanji != null && cachedKanji.isNotEmpty) {
          emit(state.copyWith(
            status: KanjiStatus.success,
            kanjiList: cachedKanji,
            selectedKanji: null,
            isAllLoaded: true,
          ));
          return; // Exit early since we have all data
        }
      }
    }
    
    // Get initial batch
    final result = await _repository.getInitialKanjiByJlptLevel(
      event.jlptLevel, 
      initialLimit: event.initialLimit
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: KanjiStatus.error,
        errorMessage: failure.toString(),
        selectedKanji: null,
      )),
      (kanjiList) {
        // Show initial results
        emit(state.copyWith(
          status: KanjiStatus.loadingMore, // Immediately show loading more status
          kanjiList: kanjiList,
          selectedKanji: null,
        ));
        
        // Start background loading for remaining kanji
        add(LoadRemainingKanjiByJlptLevel(event.jlptLevel));
      },
    );
  }
  
  // Step 2: Load all remaining kanji in the background
  Future<void> _onLoadRemainingKanjiByJlptLevel(
    LoadRemainingKanjiByJlptLevel event,
    Emitter<KanjiState> emit,
  ) async {
    // Only start background loading if we're not already loading
    if (state.status == KanjiStatus.loadingMore) {
      // Cancel any existing background task
      await _backgroundLoadingSubscription?.cancel();
      
      // Start a new background task
      _backgroundLoadingSubscription = Stream.fromFuture(
        _repository.getAllKanjiByJlptLevel(event.jlptLevel)
      ).listen((result) {
        result.fold(
          (failure) => add(ClearError()), // Just clear the loading status on error
          (allKanjiList) {
            // Update the state with all kanji
            add(_UpdateKanjiList(allKanjiList, isAllLoaded: true));
          },
        );
      });
    }
  }
  
  // Internal event to update kanji list from background loading
  Future<void> _onUpdateKanjiList(
    _UpdateKanjiList event,
    Emitter<KanjiState> emit,
  ) async {
    emit(state.copyWith(
      status: KanjiStatus.success,
      kanjiList: event.kanjiList,
      isAllLoaded: event.isAllLoaded,
    ));
  }
  
  // Handle pagination
  void _onChangePage(
    ChangePage event,
    Emitter<KanjiState> emit,
  ) {
    // Validate page number
    if (event.page >= 0 && 
        (event.page * state.itemsPerPage < state.kanjiList.length || event.page == 0)) {
      emit(state.copyWith(currentPage: event.page));
    }
  }

  Future<void> _onSelectKanji(
    SelectKanji event,
    Emitter<KanjiState> emit,
  ) async {
    emit(state.copyWith(status: KanjiStatus.loading));
    try {
      final result = await _repository.getKanjiDetails(event.kanji);
      result.fold(
        (failure) => emit(state.copyWith(
          status: KanjiStatus.error,
          errorMessage: failure.toString(),
        )),
        (kanji) => emit(state.copyWith(
          status: KanjiStatus.success,
          selectedKanji: kanji,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: KanjiStatus.error,
        errorMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  void _onClearError(
    ClearError event,
    Emitter<KanjiState> emit,
  ) {
    emit(state.copyWith(
      status: KanjiStatus.initial,
      errorMessage: null,
    ));
  }
}
