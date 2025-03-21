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
      
      // First, ensure the user document exists
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        // Create the user document if it doesn't exist
        batch.set(userRef, {
          'createdAt': FieldValue.serverTimestamp(),
          'savedWords': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
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
      batch.set(listRef, {
        'wordCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update the user's saved words count
      batch.set(userRef, {
        'savedWords': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add word to list: $e');
    }
  }

  // Remove a word from a list
  Future<void> removeWordFromList(String listId, String wordId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(user.uid);
      final listRef = userRef.collection('word_lists').doc(listId);
      
      // Remove the word reference from the list
      final listWordRef = listRef.collection('words').doc(wordId);
      batch.delete(listWordRef);
      
      // Update the word count in the list document
      batch.update(listRef, {
        'wordCount': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove word from list: $e');
    }
  }

  // Delete a word list
  Future<void> deleteWordList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all words in this list
      final wordsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('word_lists')
          .doc(listId)
          .collection('words')
          .get();
      
      // Start a batch write
      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(user.uid);
      final listRef = userRef.collection('word_lists').doc(listId);
      
      // Delete all word references in the list
      for (var doc in wordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the list document
      batch.delete(listRef);
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete word list: $e');
    }
  }

  // Get words in a specific list
  Stream<List<SavedWord>> getWordsInList(String listId) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('word_lists')
        .doc(listId)
        .collection('words')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final wordIds = snapshot.docs.map((doc) => doc.id).toList();
      
      if (wordIds.isEmpty) {
        return [];
      }
      
      // Get the actual saved words
      final savedWordsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_words')
          .where(FieldPath.documentId, whereIn: wordIds)
          .get();
      
      return savedWordsQuery.docs.map((doc) => SavedWord.fromFirestore(doc)).toList();
    });
  }
}
