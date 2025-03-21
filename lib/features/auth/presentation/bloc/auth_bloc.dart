import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/firebase_auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required FirebaseAuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthState.initial()) {
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<EmailSignUpRequested>(_onEmailSignUpRequested);
    on<StartAuthListening>(_onStartAuthListening);
    on<EmailSignInRequested>(_onEmailSignInRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  void _onStartAuthListening(
    StartAuthListening event,
    Emitter<AuthState> emit,
  ) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthEvent.authStateChanged(user)),
    );
  }

  void _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthState.loading());
      print('Starting Google Sign In process...');
      final userCredential = await _authRepository.signInWithGoogle();
      print('Google Sign In successful. User ID: ${userCredential.user?.uid}');
      emit(AuthState.authenticated(userCredential.user!.uid));
    } catch (e) {
      print('Failed to sign in with Google: $e');
      
      String errorMessage;
      if (e.toString().contains('PigeonUserDetails')) {
        errorMessage = 'Authentication error. Please try signing out and in again';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = 'Google Sign In was cancelled or failed';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error occurred. Please check your connection';
      } else if (e.toString().contains('credential')) {
        errorMessage = 'Invalid credentials. Please try again';
      } else {
        errorMessage = 'Failed to sign in with Google: ${e.toString()}';
      }
      
      emit(AuthState.error(errorMessage));
    }
  }

  void _onEmailSignUpRequested(
    EmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthState.loading());
      final userCredential = await _authRepository.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      emit(AuthState.authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void _onEmailSignInRequested(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthState.loading());
      final userCredential = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthState.loading());
      
      // Cancel the auth state subscription first to prevent any unexpected state changes
      await _authStateSubscription?.cancel();
      
      // Sign out with a timeout to prevent hanging
      bool signOutCompleted = false;
      
      try {
        await _authRepository.signOut();
        signOutCompleted = true;
      } catch (e) {
        print('Error during sign out: $e');
        // Continue with the logout flow even if there's an error
      }
      
      // Always emit Unauthenticated state after sign-out attempt
      emit(AuthState.unauthenticated());
      
      // If sign out was successful, restart auth listening
      if (signOutCompleted) {
        // Delay slightly to ensure Firebase has time to process the logout
        await Future.delayed(const Duration(milliseconds: 500));
        add(AuthEvent.startAuthListening());
      }
    } catch (e) {
      print('Critical error during sign out: $e');
      // Even if there's an error, we still want to transition to Unauthenticated
      // to prevent the UI from being stuck in the loading state
      emit(AuthState.unauthenticated());
      
      // Restart auth listening in case of error
      add(AuthEvent.startAuthListening());
    }
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      final user = event.user as User;
      emit(AuthState.authenticated(user.uid));
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  void _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthState.loading());
      await _authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
