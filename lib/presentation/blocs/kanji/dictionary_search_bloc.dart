import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/repositories/kanji_repository.dart';

part 'dictionary_search_event.dart';
part 'dictionary_search_state.dart';

@injectable
class DictionarySearchBloc extends Bloc<DictionarySearchEvent, DictionarySearchState> {
  final KanjiRepository _repository;

  DictionarySearchBloc(this._repository) : super(DictionarySearchInitial()) {
    on<SearchDictionaryWords>(_onSearchDictionaryWords);
    on<ClearDictionarySearch>(_onClearDictionarySearch);
  }

  Future<void> _onSearchDictionaryWords(
    SearchDictionaryWords event,
    Emitter<DictionarySearchState> emit,
  ) async {
    emit(DictionarySearchLoading());
    
    final result = await _repository.searchDictionaryWords(event.query);
    
    result.fold(
      (failure) => emit(DictionarySearchError(message: failure.toString())),
      (results) => emit(DictionarySearchLoaded(results: results)),
    );
  }

  void _onClearDictionarySearch(
    ClearDictionarySearch event,
    Emitter<DictionarySearchState> emit,
  ) {
    emit(DictionarySearchInitial());
  }
}
