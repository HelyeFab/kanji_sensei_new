import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/saved_word.dart';

class SavedWordsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SavedWordsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<bool> isWordSaved(String word) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_words')
          .where('word', isEqualTo: word.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if word is saved: $e');
    }
  }

  Future<void> saveWord(SavedWord word) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if word is already saved
      if (await isWordSaved(word.word)) {
        throw Exception('Word is already saved');
      }

      // Start a batch write
      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(user.uid);
      final wordsRef = userRef.collection('saved_words');

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

      // Add the word
      batch.set(wordsRef.doc(word.id), word.toFirestore());

      // Update saved words count
      batch.set(userRef, {
        'savedWords': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save word: $e');
    }
  }

  Future<void> removeWord(String wordId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(user.uid);
      final wordRef = userRef.collection('saved_words').doc(wordId);

      // Delete the word
      batch.delete(wordRef);

      // Update saved words count
      batch.set(userRef, {
        'savedWords': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove word: $e');
    }
  }

  Future<void> updateWord(SavedWord word) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final wordRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_words')
          .doc(word.id);

      // First verify the document exists
      final doc = await wordRef.get();
      if (!doc.exists) {
        throw Exception('Word document does not exist: ${word.id}');
      }

      await wordRef.update(word.toFirestore());
    } catch (e) {
      throw Exception('Failed to update word: $e');
    }
  }

  Stream<List<SavedWord>> getSavedWords({String? language}) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_words');

    // First filter by language if specified, then order by savedAt
    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }
    
    // Apply ordering after any filters
    query = query.orderBy('savedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SavedWord.fromFirestore(doc);
      }).toList();
    });
  }

  Future<List<SavedWord>> getSavedWordsList({String? language}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_words');

    // First filter by language if specified, then order by savedAt
    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }
    
    // Apply ordering after any filters
    query = query.orderBy('savedAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SavedWord.fromFirestore(doc)).toList();
  }

  Stream<Map<String, int>> getWordProgressCounts({String? language}) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_words');
    
    if (language != null) {
      query = query.where('language', isEqualTo: language.toLowerCase());
    }

    return query.snapshots().map((snapshot) {
      final counts = {
        'new': 0,
        'learning': 0,
        'learned': 0,
      };

      for (var doc in snapshot.docs) {
        final progress = doc.data()['progress'] as int? ?? 0;
        if (progress == 0) {
          counts['new'] = (counts['new'] ?? 0) + 1;
        } else if (progress == 1) {
          counts['learning'] = (counts['learning'] ?? 0) + 1;
        } else {
          counts['learned'] = (counts['learned'] ?? 0) + 1;
        }
      }

      return counts;
    });
  }
}
