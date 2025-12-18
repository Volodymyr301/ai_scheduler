part of 'authentication_cubit.dart';

enum AuthenticationStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthenticationState extends Equatable {
  final AuthenticationStatus status;
  final GoogleSignInAccount? user;
  final String? error;

  const AuthenticationState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthenticationState.initial() : this(status: AuthenticationStatus.initial);
  const AuthenticationState.loading() : this(status: AuthenticationStatus.loading);
  const AuthenticationState.unauthenticated() : this(status: AuthenticationStatus.unauthenticated);
  const AuthenticationState.failure(String message)
      : this(status: AuthenticationStatus.failure, error: message);
  const AuthenticationState.authenticated(GoogleSignInAccount u)
      : this(status: AuthenticationStatus.authenticated, user: u);

  @override
  List<Object?> get props => <Object?>[status, user?.id, error];
}


