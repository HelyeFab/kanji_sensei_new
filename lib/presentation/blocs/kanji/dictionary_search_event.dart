part of 'dictionary_search_bloc.dart';

abstract class DictionarySearchEvent extends Equatable {
  const DictionarySearchEvent();

  @override
  List<Object> get props => [];
}

class SearchDictionaryWords extends DictionarySearchEvent {
  final String query;

  const SearchDictionaryWords(this.query);

  @override
  List<Object> get props => [query];
}

class ClearDictionarySearch extends DictionarySearchEvent {}
