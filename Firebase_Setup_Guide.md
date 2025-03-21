# Firebase Firestore Setup Guide for Flutter Apps

This guide provides detailed steps to set up Firebase Firestore for your Flutter application, including configuring security rules, creating necessary files, and implementing the feature in your app.

## Prerequisites

- A Firebase project created in the [Firebase Console](https://console.firebase.google.com/)
- Flutter project with Firebase Core already initialized
- Firebase CLI installed (`npm install -g firebase-tools`)

## Step 1: Enable Firestore in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click on "Firestore Database"
4. Click "Create database" button
5. Choose security mode:
   - "Start in production mode" (recommended for production)
   - "Start in test mode" (for development only)
6. Click "Next"
7. Select a location closest to your users (e.g., "eur3" for Europe)
8. Click "Enable"
9. Wait for the database to be created (this may take a minute or two)

## Step 2: Set Up Firebase Configuration Files

Create the following files in your project root:

### 1. `.firebaserc`

```json
{
  "projects": {
    "default": "YOUR_PROJECT_ID"
  }
}
```

Replace `YOUR_PROJECT_ID` with your Firebase project ID.

### 2. `firebase.json`

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

### 3. `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read and write their own saved words
      match /saved_words/{wordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Allow users to read and write their own word lists
      match /word_lists/{listId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Allow users to read and write words in their lists
        match /words/{wordId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
```

### 4. `firestore.indexes.json`

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

## Step 3: Deploy Firestore Rules and Indexes

1. Log in to Firebase CLI (if not already logged in):
   ```
   firebase login
   ```

2. Deploy Firestore rules:
   ```
   firebase deploy --only firestore:rules
   ```

3. Deploy Firestore indexes:
   ```
   firebase deploy --only firestore:indexes
   ```

## Step 4: Create Entity Models

Create models for your data entities. For example, a `WordList` model:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WordList extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final int wordCount;

  const WordList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUpdated,
    this.wordCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        lastUpdated,
        wordCount,
      ];

  WordList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? wordCount,
  }) {
    return WordList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  factory WordList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordList(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      wordCount: data['wordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
      'wordCount': wordCount,
    };
  }
}
```

## Step 5: Implement Repository Classes

Create repository classes to interact with Firestore. For example, a `WordListsRepository`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/word_list.dart';
import '../../domain/entities/saved_word.dart';

class WordListsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WordListsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Get all word lists for the current user
  Stream<List<WordList>> getWordLists() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('word_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WordList.fromFirestore(doc);
      }).toList();
    });
  }

  // Create a new word list
  Future<WordList> createWordList(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if a list with this name already exists
      final existingLists = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('word_lists')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingLists.docs.isNotEmpty) {
        throw Exception('A list with this name already exists');
      }

      // Create a new list
      final listData = {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'wordCount': 0,
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('word_lists')
          .add(listData);

      // Get the created document to return
      final doc = await docRef.get();
      return WordList.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create word list: $e');
    }
  }

  // Add a word to a list
  Future<void> addWordToList(String listId, Map<String, dynamic> wordDetails) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(user.uid);
      final listRef = userRef.collection('word_lists').doc(listId);
      
      // Create a new saved word
      final savedWord = SavedWord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        word: wordDetails['word'] ?? '',
        definition: wordDetails['translation'] ?? '',
        examples: wordDetails['example'] != null ? [wordDetails['example']] : null,
        language: 'ja', // Assuming Japanese for this app
        savedAt: DateTime.now(),
      );
      
      // Add the word to the user's saved_words collection
      final wordRef = userRef.collection('saved_words').doc(savedWord.id);
      batch.set(wordRef, savedWord.toFirestore());
      
      // Add a reference to this word in the list's words subcollection
      final listWordRef = listRef.collection('words').doc(savedWord.id);
      batch.set(listWordRef, {
        'wordId': savedWord.id,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      // Update the word count in the list document
      batch.update(listRef, {
        'wordCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update the user's saved words count
      batch.update(userRef, {
        'savedWords': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add word to list: $e');
    }
  }

  // Additional methods for managing word lists...
}
```

## Step 6: Register Dependencies

Register your repositories in your dependency injection system. For example, using GetIt:

```dart
import 'package:get_it/get_it.dart';
import '../../data/repositories/word_lists_repository.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Register repositories
  getIt.registerLazySingleton<WordListsRepository>(() => WordListsRepository());
  
  // Other registrations...
}
```

## Step 7: Create UI Components

Create UI components to interact with your Firestore data. For example, a modal to save words:

```dart
import 'package:flutter/material.dart';
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

  // Implementation details...
}
```

## Step 8: Test Your Implementation

1. Make sure a user is logged in (the app uses Firebase Authentication)
2. Test creating new lists
3. Test saving words to lists
4. Test viewing and managing saved word lists

## Troubleshooting

### Common Issues:

1. **Authentication Errors**: Make sure Firebase Authentication is properly set up and a user is logged in before trying to access Firestore.

2. **Permission Denied**: Check your Firestore security rules if you're getting permission errors.

3. **Missing Collections**: Firestore collections are created lazily when you first add a document. If you don't see a collection, it might be because no documents have been added yet.

4. **Deployment Errors**: If you encounter errors deploying rules or indexes, check that your Firebase CLI is properly configured and you're logged in to the correct account.

### Firebase CLI Commands:

- Check Firebase CLI version: `firebase --version`
- Login to Firebase: `firebase login`
- List Firebase projects: `firebase projects:list`
- Set active project: `firebase use <project-id>`
- Deploy all Firebase resources: `firebase deploy`
- Deploy only Firestore rules: `firebase deploy --only firestore:rules`
- Deploy only Firestore indexes: `firebase deploy --only firestore:indexes`

## Additional Resources

- [Firebase Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Firebase Plugins](https://firebase.flutter.dev/docs/overview)
