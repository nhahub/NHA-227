abstract class AuthEvent {}

class SignInEvent extends AuthEvent {
  final String emailOrPhone;
  final String password;

  SignInEvent(this.emailOrPhone, this.password);
}

class SignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  SignUpEvent({required this.name, required this.email, required this.password});
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent(this.email);
}

class SignOutEvent extends AuthEvent {}