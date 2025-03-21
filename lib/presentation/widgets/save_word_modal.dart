import 'package:flutter/material.dart';

class SaveWordModal extends StatefulWidget {
  final Map<String, dynamic> wordDetails;

  const SaveWordModal({super.key, required this.wordDetails});

  @override
  State<SaveWordModal> createState() => _SaveWordModalState();
}

class _SaveWordModalState extends State<SaveWordModal> {
  final _listNameController = TextEditingController();

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Word to New List'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: _listNameController,
              decoration: const InputDecoration(
                hintText: 'Enter new list name',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Create New List'),
          onPressed: () {
            String listName = _listNameController.text;
            if (listName.isNotEmpty) {
              // TODO: Implement save logic with listName and widget.wordDetails
              print('Create list: $listName with word: ${widget.wordDetails['word']}');
              Navigator.of(context).pop();
            } else {
              // Optionally show an error message if list name is empty
              print('List name cannot be empty');
            }
          },
        ),
      ],
    );
  }
}
