import 'package:kudipay/model/user/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Create a loading state
  AuthState loading() {
    return copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );
  }

  // Create an authenticated state
  AuthState authenticated(UserModel user, String token) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
      errorMessage: null,
    );
  }

  // Create an unauthenticated state
  AuthState unauthenticated([String? message]) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
      errorMessage: message,
    );
  }

  // Create an error state
  AuthState error(String message) {
    return copyWith(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}