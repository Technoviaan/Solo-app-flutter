abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSent extends AuthState {}

class AuthVerified extends AuthState {

  final bool nameCompleted;
  final bool emailCompleted;

  AuthVerified({
    required this.nameCompleted,
    required this.emailCompleted,
  });
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}