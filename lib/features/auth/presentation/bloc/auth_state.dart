part of 'auth_bloc.dart';

abstract class AuthState {
  const AuthState();

  factory AuthState.initial() = _Initial;
  factory AuthState.loading() = _Loading;
  factory AuthState.authenticated(String uid) = _Authenticated;
  factory AuthState.unauthenticated() = _Unauthenticated;
  factory AuthState.error(String message) = _Error;
  
  // Helper method to handle state pattern matching
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(String uid) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is _Initial) return initial();
    if (this is _Loading) return loading();
    if (this is _Authenticated) return authenticated((this as _Authenticated).uid);
    if (this is _Unauthenticated) return unauthenticated();
    if (this is _Error) return error((this as _Error).message);
    throw Exception('Unknown state: $this');
  }
  
  // Helper method to handle state pattern matching with default case
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is _Initial && initial != null) return initial();
    if (this is _Loading && loading != null) return loading();
    if (this is _Authenticated && authenticated != null) {
      return authenticated((this as _Authenticated).uid);
    }
    if (this is _Unauthenticated && unauthenticated != null) return unauthenticated();
    if (this is _Error && error != null) return error((this as _Error).message);
    return orElse();
  }
}

class _Initial extends AuthState {
  const _Initial();
}

class _Loading extends AuthState {
  const _Loading();
}

class _Authenticated extends AuthState {
  final String uid;

  const _Authenticated(this.uid);
}

class _Unauthenticated extends AuthState {
  const _Unauthenticated();
}

class _Error extends AuthState {
  final String message;

  const _Error(this.message);
}
