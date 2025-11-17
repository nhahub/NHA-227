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

class PhoneCodeSentEvent extends AuthEvent {
  final String phoneNumber;

  PhoneCodeSentEvent(this.phoneNumber);
}

class PhoneCodeVerifiedEvent extends AuthEvent {
  final String smsCode;

  PhoneCodeVerifiedEvent(this.smsCode);
}

class SendVerificationCodeEvent extends AuthEvent {
  final String contact; // phone number or email
  final bool isSms;
  final String? email;  // for verification event

  SendVerificationCodeEvent({required this.contact, required this.isSms, this.email});
}

class VerifyCodeEvent extends AuthEvent {
  final String code;
  final bool isSms;
  final String? email;

  VerifyCodeEvent({required this.code, required this.isSms, this.email});
}

class ResendCodeEvent extends AuthEvent {
  final String contact;
  final bool isSms;

  ResendCodeEvent({required this.contact, required this.isSms});
}
class GoogleSignInEvent extends AuthEvent {}
