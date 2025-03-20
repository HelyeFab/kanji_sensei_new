part of 'dictionary_search_bloc.dart';

abstract class DictionarySearchState extends Equatable {
  const DictionarySearchState();
  
  @override
  List<Object?> get props => [];
}

class DictionarySearchInitial extends DictionarySearchState {}

class DictionarySearchLoading extends DictionarySearchState {}

class DictionarySearchLoaded extends DictionarySearchState {
  final List<Map<String, dynamic>> results;

  const DictionarySearchLoaded({required this.results});

  @override
  List<Object?> get props => [results];
}

class DictionarySearchError extends DictionarySearchState {
  final String message;

  const DictionarySearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
