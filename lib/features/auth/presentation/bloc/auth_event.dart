part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();

  factory AuthEvent.googleSignInRequested() = GoogleSignInRequested;
  factory AuthEvent.emailSignUpRequested({
    required String email,
    required String password,
    required String name,
  }) = EmailSignUpRequested;
  factory AuthEvent.emailSignInRequested({
    required String email,
    required String password,
  }) = EmailSignInRequested;
  factory AuthEvent.signOutRequested() = SignOutRequested;
  factory AuthEvent.authStateChanged(dynamic user) = AuthStateChanged;
  factory AuthEvent.startAuthListening() = StartAuthListening;
  factory AuthEvent.passwordResetRequested({
    required String email,
  }) = PasswordResetRequested;
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class EmailSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const EmailSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });
}

class EmailSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const EmailSignInRequested({
    required this.email,
    required this.password,
  });
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class AuthStateChanged extends AuthEvent {
  final dynamic user;

  const AuthStateChanged(this.user);
}

class StartAuthListening extends AuthEvent {
  const StartAuthListening();
}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});
}
