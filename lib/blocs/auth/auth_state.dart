import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class AuthPasswordResetEmailSent extends AuthState {}
class CodeSentState extends AuthState {}

class CodeVerificationInProgress extends AuthState {}

class CodeVerificationSuccess extends AuthState {}

class CodeVerificationFailure extends AuthState {
  final String error;
  CodeVerificationFailure(this.error);
}

class ResendCodeInProgress extends AuthState {}

class ResendCodeSuccess extends AuthState {}

class ResendCodeFailure extends AuthState {
  final String error;
  ResendCodeFailure(this.error);
}