import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_stats.dart';

class UserStatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserStatsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<UserStats> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the stats document
      final statsDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('current');

      final statsSnap = await statsDocRef.get();
      if (!statsSnap.exists) {
        await _initializeUserStats(user.uid);
        // Get the newly created stats
        final newStatsSnap = await statsDocRef.get();
        if (!newStatsSnap.exists) {
          throw Exception('Failed to initialize user stats');
        }
        return const UserStats(
          savedWords: 0,
          readingStreak: 0,
        );
      }

      return UserStats.fromFirestore(statsSnap);
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  Stream<UserStats> streamUserStats() async* {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('current');

    // First check if we need to initialize
    final doc = await docRef.get();
    if (!doc.exists) {
      await _initializeUserStats(user.uid);
    }

    // Now stream the document
    await for (final doc in docRef.snapshots()) {
      if (doc.exists) {
        yield UserStats.fromFirestore(doc);
      } else {
        yield const UserStats();
      }
    }
  }

  Future<void> _initializeUserStats(String userId) async {
    try {
      // Create a default UserStats instance
      const defaultStats = UserStats(
        savedWords: 0,
        readingStreak: 0,
        readDates: [],
      );

      // Convert to Firestore data using the model's toFirestore method
      final data = defaultStats.toFirestore();
      
      // Add server timestamp
      data['lastUpdated'] = FieldValue.serverTimestamp();

      // First ensure user document exists
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'email': _auth.currentUser?.email,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      // Then create stats document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('current')
          .set(data);
      
    } catch (e) {
      throw Exception('Failed to initialize user stats: $e');
    }
  }

  Future<void> incrementSavedWords() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('current')
          .set({
        'savedWords': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to increment saved words: $e');
    }
  }

  Future<void> decrementSavedWords() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('current');

      // Get current stats to prevent negative values
      final currentStats = await getUserStats();
      if (currentStats.savedWords <= 0) {
        return;
      }

      // Update the stats only if we have saved words to decrement
      await docRef.set({
        'savedWords': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to decrement saved words: $e');
    }
  }

  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Use a transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        final statsRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('current');
        
        // Get current stats in transaction
        final statsDoc = await transaction.get(statsRef);
        
        if (!statsDoc.exists) {
          throw Exception('Stats document not found');
        }
        
        final stats = UserStats.fromFirestore(statsDoc);
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Check if we already read today
        final readToday = stats.readDates.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);

        // Update streak logic
        int newStreak = stats.readingStreak;
        if (!readToday) {
          if (stats.isStreakActive()) {
            // Continue streak
            newStreak += 1;
          } else {
            // Reset streak
            newStreak = 1;
          }
        }

        // Update stats
        transaction.set(statsRef, {
          'readingStreak': newStreak,
          'lastReadDate': Timestamp.fromDate(today),
          'readDates': FieldValue.arrayUnion([Timestamp.fromDate(today)]),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }
}
