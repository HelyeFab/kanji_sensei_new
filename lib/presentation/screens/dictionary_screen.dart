import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../blocs/kanji/dictionary_search_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/kanji_search_bar.dart';
import '../widgets/dictionary_card.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      getIt<DictionarySearchBloc>().add(SearchDictionaryWords(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<DictionarySearchBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dictionary'),
          backgroundColor: AppColors.background,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: KanjiSearchBar(
                  controller: _searchController,
                  onSearch: _performSearch,
                ),
              ),
              
              // Results
              Expanded(
                child: BlocBuilder<DictionarySearchBloc, DictionarySearchState>(
                  builder: (context, state) {
                    if (state is DictionarySearchInitial) {
                      return const Center(
                        child: Text('Search for words in Japanese or English'),
                      );
                    } else if (state is DictionarySearchLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is DictionarySearchError) {
                      return Center(
                        child: Text('Error: ${state.message}'),
                      );
                    } else if (state is DictionarySearchLoaded) {
                      if (state.results.isEmpty) {
                        return const Center(
                          child: Text('No results found'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final result = state.results[index];
                          return DictionaryCard(
                            word: result['word'] ?? '',
                            partOfSpeech: result['partOfSpeech'] ?? '',
                            translation: result['translation'] ?? '',
                            example: result['example'] ?? '',
                          );
                        },
                      );
                    }
                    
                    // Default case - should not happen
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
