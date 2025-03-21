import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/auth/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required AuthService authService,
  })  : _authService = authService,
        super(const AuthInitial()) {
    on<StartAuthListening>(_onStartAuthListening);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<EmailSignInRequested>(_onEmailSignInRequested);
    on<EmailSignUpRequested>(_onEmailSignUpRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<AnonymousSignInRequested>(_onAnonymousSignInRequested);
  }

  void _onStartAuthListening(
    StartAuthListening event,
    Emitter<AuthState> emit,
  ) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateChanges.listen(
          (user) => add(AuthStateChanged(user)),
        );
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(Authenticated(event.user!.uid));
    } else {
      emit(const Unauthenticated());
    }
  }

  void _onEmailSignInRequested(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      emit(Authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onEmailSignUpRequested(
    EmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        event.email,
        event.password,
      );
      // Update user profile with name
      await userCredential.user?.updateDisplayName(event.name);
      emit(Authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.signInWithGoogle();
      emit(Authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAnonymousSignInRequested(
    AnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.signInAnonymously();
      emit(Authenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Cancel the auth state subscription first to prevent any unexpected state changes
      await _authStateSubscription?.cancel();
      
      // Sign out with a timeout to prevent hanging
      bool signOutCompleted = false;
      
      try {
        await _authService.signOut();
        signOutCompleted = true;
      } catch (e) {
        print('Error during sign out: $e');
        // Continue with the logout flow even if there's an error
      }
      
      // Always emit Unauthenticated state after sign-out attempt
      emit(const Unauthenticated());
      
      // If sign out was successful, restart auth listening
      if (signOutCompleted) {
        // Delay slightly to ensure Firebase has time to process the logout
        await Future.delayed(const Duration(milliseconds: 500));
        add(const StartAuthListening());
      }
    } catch (e) {
      print('Critical error during sign out: $e');
      // Even if there's an error, we still want to transition to Unauthenticated
      // to prevent the UI from being stuck in the loading state
      emit(const Unauthenticated());
      
      // Restart auth listening in case of error
      add(const StartAuthListening());
    }
  }

  void _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.resetPassword(event.email);
      emit(const PasswordResetSent());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
