import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/kanji/kanji_bloc.dart';
import '../blocs/kanji/kanji_event.dart';
import '../blocs/kanji/kanji_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/kanji_search_bar.dart';
import '../widgets/jlpt_level_selector.dart';
import '../widgets/kanji_detail_card.dart';

class KanjiSearchScreen extends StatefulWidget {
  const KanjiSearchScreen({super.key});

  @override
  State<KanjiSearchScreen> createState() => _KanjiSearchScreenState();
}

class _KanjiSearchScreenState extends State<KanjiSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchByJlpt = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchByJlpt) {
      final currentJlptLevel = context.read<KanjiBloc>().state.jlptLevel;
      if (currentJlptLevel > 0) {
        context
            .read<KanjiBloc>()
            .add(LoadInitialKanjiByJlptLevel(currentJlptLevel));
      }
    } else {
      if (_searchController.text.isEmpty) return;

      FocusScope.of(context).unfocus();

      // Search by kanji character
      if (_searchController.text.length == 1) {
        // If it's a single character, get details for that kanji
        context.read<KanjiBloc>().add(
              SelectKanji(_searchController.text),
            );
      } else {
        // Otherwise, search for kanji
        context.read<KanjiBloc>().add(
              SearchKanji(_searchController.text),
            );
      }
    }
  }
  
  // Direct method to clear selected kanji
  void _clearSelectedKanji() {
    print('_clearSelectedKanji called directly');
    // Use a direct approach to clear the selected kanji
    final kanjiBloc = context.read<KanjiBloc>();
    
    // First try with the event
    kanjiBloc.add(ClearSelectedKanji());
    
    // Also try with a direct SelectKanji(null) event as a fallback
    kanjiBloc.add(SelectKanji(null));
    
    print('Both ClearSelectedKanji and SelectKanji(null) events dispatched');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kanji Search'),
        backgroundColor: AppColors.background,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          // Tap dismissal removed as requested
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: KanjiSearchBar(
                  controller: _searchController,
                  onSearch: () {
                    setState(() {
                      _searchByJlpt = false;
                    });
                    _performSearch();
                  },
                  hintText: 'Search for a kanji',
                ),
              ),
              const SizedBox(height: 8),
              // Text divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              // JLPT Levels header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/award.png',
                      width: 36,
                      height: 36,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'JLPT Levels',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // JLPT Level Selector
              BlocBuilder<KanjiBloc, KanjiState>(
                builder: (context, state) {
                  return JlptLevelSelector(
                    selectedLevel: state.jlptLevel,
                    onLevelSelected: (level) {
                      context
                          .read<KanjiBloc>()
                          .add(LoadInitialKanjiByJlptLevel(level));
                      setState(() => _searchByJlpt = true);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<KanjiBloc, KanjiState>(
                  builder: (context, state) {
                    print('BlocBuilder rebuilding with state: ${state.status}, selectedKanji: ${state.selectedKanji != null}');
                    
                    if (state.status == KanjiStatus.loading) {
                      print('Showing loading indicator');
                      return const Center(child: CircularProgressIndicator());
                    } else if (state.status == KanjiStatus.loadingMore) {
                      print('Showing loading more UI');
                      // Show results with a loading indicator for background loading
                      return _buildKanjiListWithLoading(state);
                    } else if (state.status == KanjiStatus.error) {
                      print('Showing error UI');
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'An error occurred while searching',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Please try again with a different search term',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (state.selectedKanji != null) {
                      print('Showing kanji detail card for: ${state.selectedKanji!.character}');
                      return KanjiDetailCard(
                        kanji: state.selectedKanji!,
                        onClose: _clearSelectedKanji,
                      );
                    } else if (state.kanjiList.isNotEmpty) {
                      print('Showing paginated kanji list with ${state.kanjiList.length} items');
                      return _buildPaginatedKanjiList(state);
                    } else {
                      print('Showing empty state message');
                      return Center(
                        child: Text(_searchByJlpt
                            ? 'Select a JLPT level and press Search'
                            : 'Enter a kanji to search'),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for showing kanji list with pagination
  Widget _buildPaginatedKanjiList(KanjiState state) {
    return Column(
      children: [
        // Show loading status if background loading is complete
        if (state.isAllLoaded && state.totalKanjiCount != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Loaded ${state.kanjiList.length} kanji for JLPT N${state.jlptLevel}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
          ),

        // Main kanji list
        Expanded(
          child: ListView.builder(
            itemCount: state.currentPageKanji.length,
            itemBuilder: (context, index) {
              final kanji = state.currentPageKanji[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.primary, width: 3),
                ),
                child: InkWell(
                  onTap: () {
                    context.read<KanjiBloc>().add(SelectKanji(kanji.character));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kanji.character,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kanji.meanings.join(', '),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (kanji.onReadings.isNotEmpty ||
                            kanji.kunReadings.isNotEmpty)
                          Text(
                            'Example sentence would go here.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination controls
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous page button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.hasPreviousPage
                    ? () => context
                        .read<KanjiBloc>()
                        .add(ChangePage(state.currentPage - 1))
                    : null,
              ),

              // Page indicator
              Text(
                'Page ${state.currentPage + 1} of ${state.availablePages}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              // Next page button
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: state.hasNextPage
                    ? () => context
                        .read<KanjiBloc>()
                        .add(ChangePage(state.currentPage + 1))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for showing kanji list with background loading indicator
  Widget _buildKanjiListWithLoading(KanjiState state) {
    return Column(
      children: [
        // Loading indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading all kanji for JLPT N${state.jlptLevel}...',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        // Kanji list (same as in _buildPaginatedKanjiList but with simplified card)
        Expanded(
          child: ListView.builder(
            itemCount: state.currentPageKanji.length,
            itemBuilder: (context, index) {
              final kanji = state.currentPageKanji[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.primary, width: 3),
                ),
                child: InkWell(
                  onTap: () {
                    context.read<KanjiBloc>().add(SelectKanji(kanji.character));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kanji.character,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kanji.meanings.join(', '),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination controls
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.hasPreviousPage
                    ? () => context
                        .read<KanjiBloc>()
                        .add(ChangePage(state.currentPage - 1))
                    : null,
              ),
              Text(
                'Page ${state.currentPage + 1} of ${state.availablePages}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: state.hasNextPage
                    ? () => context
                        .read<KanjiBloc>()
                        .add(ChangePage(state.currentPage + 1))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
