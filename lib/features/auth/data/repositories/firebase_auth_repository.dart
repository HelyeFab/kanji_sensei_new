import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Try to get the current signed-in user first
      GoogleSignInAccount? googleUser;
      try {
        // Try to get the current signed-in user first
        googleUser = await _googleSignIn.signInSilently();
        
        // If no current user, trigger the sign-in flow
        googleUser ??= await _googleSignIn.signIn();
      } catch (e) {
        // If we get the PigeonUserDetails error, verify we have both a valid Google user and Firebase user
        if (e.toString().contains('PigeonUserDetails') && googleUser != null) {
          // Verify Firebase user exists
          final currentUser = _firebaseAuth.currentUser;
          if (currentUser != null && currentUser.email == googleUser.email) {
            print('Continuing with existing Firebase user despite PigeonUserDetails warning');
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      if (googleUser == null) {
        throw Exception('Sign in aborted by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        throw Exception('No access token received from Google');
      }
      
      // First check if we're already signed in with the correct email
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser?.email == googleUser.email) {
        print('Already signed in with correct email');
        // Re-authenticate to refresh tokens
        try {
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final result = await currentUser!.reauthenticateWithCredential(credential);
          print('Successfully reauthenticated existing user');
          return result;
        } catch (e) {
          print('Reauthentication failed, but continuing with existing user');
          // Even if reauthentication fails, we can continue if the user is valid
          final email = currentUser?.email;
          if (email != null && email == googleUser.email) {
            // Force a user reload to ensure we have fresh data
            await currentUser?.reload();
            // Try to get a fresh instance of the user
            final freshUser = _firebaseAuth.currentUser;
            if (freshUser != null) {
              // Create a new credential using the Google provider
              final newCredential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              return await freshUser.linkWithCredential(newCredential);
            }
          }
        }
      }

      // If not already signed in or email doesn't match, sign in with new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      return userCredential;
    } catch (e) {
      print('Failed to sign in with Google: $e');
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with email and password: $e');
    }
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);
      
      return userCredential;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // First, ensure we're disconnected from Firestore
      // This helps prevent issues with lingering listeners
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
      
      // Then attempt to sign out from Google, but don't let it block the process
      try {
        // Use a shorter timeout for Google sign-out since it's causing issues
        bool googleSignOutCompleted = false;
        
        await Future.any([
          _googleSignIn.signOut().then((_) {
            googleSignOutCompleted = true;
            print('Google sign out completed successfully');
          }),
          Future.delayed(const Duration(seconds: 1)).then((_) {
            if (!googleSignOutCompleted) {
              print('Google sign out timed out after 1 second, continuing anyway');
            }
          })
        ]);
      } catch (e) {
        // Check for GoogleApiManager errors specifically
        if (e.toString().contains('GoogleApiManager')) {
          print('GoogleApiManager error during sign out (known issue, continuing)');
        } else {
          print('Google sign out error (continuing anyway): $e');
        }
        // Continue regardless of Google sign-out errors
      }
      
      // Finally, sign out from Firebase which is the most critical part
      await _firebaseAuth.signOut();
      
      // Reinitialize Firestore after logout
      await FirebaseFirestore.instance.enableNetwork();
      
      print('Sign out process completed');
    } catch (e) {
      // Even if there's an error, try to re-enable Firestore
      try {
        await FirebaseFirestore.instance.enableNetwork();
      } catch (_) {
        // Ignore any errors here
      }
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }
}
