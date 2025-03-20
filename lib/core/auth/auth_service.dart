import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dartz/dartz.dart';

class AuthFailure {
  final String code;
  final String message;

  AuthFailure({required this.code, required this.message});
}

class AuthService {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    required this.firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => firebaseAuth.authStateChanges();

  Future<Either<AuthFailure, UserCredential>> signIn(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        code: e.code,
        message: e.message ?? 'Authentication failed',
      ));
    }
  }

  Future<Either<AuthFailure, UserCredential>> signUp(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        code: e.code,
        message: e.message ?? 'Registration failed',
      ));
    }
  }

  Future<Either<AuthFailure, void>> signOut() async {
    return signOutGoogle();
  }

  Future<Either<AuthFailure, void>> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        code: e.code,
        message: e.message ?? 'Password reset failed',
      ));
    }
  }

  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If sign in was aborted
      if (googleUser == null) {
        return Left(AuthFailure(
          code: 'sign-in-cancelled',
          message: 'Google sign in was cancelled by the user',
        ));
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await firebaseAuth.signInWithCredential(credential);
      return Right(userCredential);
    } catch (e) {
      return Left(AuthFailure(
        code: 'google-sign-in-failed',
        message: 'Failed to sign in with Google: ${e.toString()}',
      ));
    }
  }

  Future<Either<AuthFailure, void>> signOutGoogle() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(
        code: 'sign-out-failed',
        message: 'Failed to sign out: ${e.toString()}',
      ));
    }
  }
}
