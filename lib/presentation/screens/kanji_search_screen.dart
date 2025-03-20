import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/kanji/kanji_bloc.dart';
import '../blocs/kanji/kanji_event.dart';
import '../blocs/kanji/kanji_state.dart';
import '../../domain/entities/kanji.dart';

class KanjiSearchScreen extends StatefulWidget {
  const KanjiSearchScreen({super.key});

  @override
  State<KanjiSearchScreen> createState() => _KanjiSearchScreenState();
}

class _KanjiSearchScreenState extends State<KanjiSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchByJlpt = false;
  int _selectedJlptLevel = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchByJlpt) {
      // Search by JLPT level - use new event for improved loading
      context.read<KanjiBloc>().add(
        LoadInitialKanjiByJlptLevel(_selectedJlptLevel),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanji Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_searchByJlpt)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Enter a kanji character (e.g. 水)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _performSearch,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _searchByJlpt,
                    onChanged: (value) {
                      setState(() {
                        _searchByJlpt = value ?? false;
                      });
                    },
                  ),
                  const Text('Search by JLPT level'),
                ],
              ),
              if (_searchByJlpt)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Text('JLPT Level: '),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _selectedJlptLevel,
                        items: [1, 2, 3, 4, 5].map((level) {
                          return DropdownMenuItem<int>(
                            value: level,
                            child: Text('N$level'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedJlptLevel = value ?? 1;
                          });
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _performSearch,
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<KanjiBloc, KanjiState>(
                  builder: (context, state) {
                    if (state.status == KanjiStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state.status == KanjiStatus.loadingMore) {
                      // Show results with a loading indicator for background loading
                      return _buildKanjiListWithLoading(state);
                    } else if (state.status == KanjiStatus.error) {
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
                      return _buildKanjiDetails(state.selectedKanji!);
                    } else if (state.kanjiList.isNotEmpty) {
                      return _buildPaginatedKanjiList(state);
                    } else {
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
              'Loaded ${state.kanjiList.length} kanji for JLPT N$_selectedJlptLevel',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.deepPurple,
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
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text(
                    kanji.character,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(kanji.meanings.join(', ')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.onReadings.isNotEmpty)
                        Text('On: ${kanji.onReadings.join(', ')}'),
                      if (kanji.kunReadings.isNotEmpty)
                        Text('Kun: ${kanji.kunReadings.join(', ')}'),
                    ],
                  ),
                  onTap: () {
                    context.read<KanjiBloc>().add(SelectKanji(kanji.character));
                  },
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
                    ? () => context.read<KanjiBloc>().add(ChangePage(state.currentPage - 1))
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
                    ? () => context.read<KanjiBloc>().add(ChangePage(state.currentPage + 1))
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
                'Loading all kanji for JLPT N$_selectedJlptLevel...',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        
        // Kanji list (same as in _buildPaginatedKanjiList)
        Expanded(
          child: ListView.builder(
            itemCount: state.currentPageKanji.length,
            itemBuilder: (context, index) {
              final kanji = state.currentPageKanji[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text(
                    kanji.character,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(kanji.meanings.join(', ')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.onReadings.isNotEmpty)
                        Text('On: ${kanji.onReadings.join(', ')}'),
                      if (kanji.kunReadings.isNotEmpty)
                        Text('Kun: ${kanji.kunReadings.join(', ')}'),
                    ],
                  ),
                  onTap: () {
                    context.read<KanjiBloc>().add(SelectKanji(kanji.character));
                  },
                ),
              );
            },
          ),
        ),
        
        // Pagination controls (same as in _buildPaginatedKanjiList)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.hasPreviousPage
                    ? () => context.read<KanjiBloc>().add(ChangePage(state.currentPage - 1))
                    : null,
              ),
              Text(
                'Page ${state.currentPage + 1} of ${state.availablePages}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: state.hasNextPage
                    ? () => context.read<KanjiBloc>().add(ChangePage(state.currentPage + 1))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKanjiDetails(Kanji kanji) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  kanji.character,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection('Meanings', kanji.meanings.join(', ')),
              _buildSection('On Readings', kanji.onReadings.join(', ')),
              _buildSection('Kun Readings', kanji.kunReadings.join(', ')),
              _buildSection('Stroke Count', kanji.strokeCount.toString()),
              _buildSection('JLPT Level', 'N${kanji.jlptLevel}'),
              if (kanji.grade != null)
                _buildSection('Grade', kanji.grade.toString()),
              if (kanji.heisigEn != null)
                _buildSection('Heisig Keyword', kanji.heisigEn!),
              if (kanji.nameReadings.isNotEmpty)
                _buildSection('Name Readings', kanji.nameReadings.join(', ')),
              if (kanji.notes.isNotEmpty)
                _buildSection('Notes', kanji.notes.join('\n')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
