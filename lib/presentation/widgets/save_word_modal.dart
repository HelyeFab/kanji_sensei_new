import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/word_lists_repository.dart';
import '../../domain/entities/word_list.dart';

class SaveWordModal extends StatefulWidget {
  final Map<String, dynamic> wordDetails;

  const SaveWordModal({super.key, required this.wordDetails});

  @override
  State<SaveWordModal> createState() => _SaveWordModalState();
}

class _SaveWordModalState extends State<SaveWordModal> {
  final _listNameController = TextEditingController();
  final _wordListsRepository = getIt<WordListsRepository>();
  String? _selectedListId;
  bool _isCreatingNewList = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  Future<void> _createNewList() async {
    final listName = _listNameController.text.trim();
    if (listName.isEmpty) {
      setState(() {
        _errorMessage = 'List name cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You need to be logged in to save words');
      }

      final newList = await _wordListsRepository.createWordList(listName);
      await _wordListsRepository.addWordToList(newList.id, widget.wordDetails);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word saved to "$listName"')),
        );
      }
    } catch (e) {
      setState(() {
        // Format the error message to be more user-friendly
        String errorMsg = e.toString();
        if (errorMsg.contains('cloud_firestore/not-found')) {
          errorMsg = 'Failed to add word to list: Document not found. Please make sure you are logged in.';
        } else if (errorMsg.contains('permission-denied')) {
          errorMsg = 'Permission denied. Please make sure you are logged in.';
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToExistingList() async {
    if (_selectedListId == null) {
      setState(() {
        _errorMessage = 'Please select a list';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You need to be logged in to save words');
      }
      
      await _wordListsRepository.addWordToList(_selectedListId!, widget.wordDetails);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word saved to list')),
        );
      }
    } catch (e) {
      setState(() {
        // Format the error message to be more user-friendly
        String errorMsg = e.toString();
        if (errorMsg.contains('cloud_firestore/not-found')) {
          errorMsg = 'Failed to add word to list: Document not found. Please make sure you are logged in.';
        } else if (errorMsg.contains('permission-denied')) {
          errorMsg = 'Permission denied. Please make sure you are logged in.';
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreatingNewList ? 'Create New List' : 'Save Word to List'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isCreatingNewList)
                    TextField(
                      controller: _listNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter new list name',
                      ),
                      autofocus: true,
                    )
                  else
                    StreamBuilder<List<WordList>>(
                      stream: _wordListsRepository.getWordLists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        final lists = snapshot.data ?? [];
                        
                        if (lists.isEmpty) {
                          return const Text('No lists found. Create a new list.');
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select a list:'),
                            const SizedBox(height: 8),
                            ...lists.map((list) => RadioListTile<String>(
                                  title: Text(list.name),
                                  subtitle: Text('${list.wordCount} words'),
                                  value: list.id,
                                  groupValue: _selectedListId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedListId = value;
                                    });
                                  },
                                )),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
      actions: _isLoading
          ? null
          : <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              if (_isCreatingNewList)
                TextButton(
                  onPressed: _createNewList,
                  child: const Text('Create & Save'),
                )
              else
                TextButton(
                  child: const Text('New List'),
                  onPressed: () {
                    setState(() {
                      _isCreatingNewList = true;
                    });
                  },
                ),
              if (!_isCreatingNewList)
                TextButton(
                  onPressed: _saveToExistingList,
                  child: const Text('Save'),
                ),
            ],
    );
  }
}
