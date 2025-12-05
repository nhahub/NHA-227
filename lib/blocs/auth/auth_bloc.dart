import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<SignOutEvent>(_onSignOut);

    on<SendVerificationCodeEvent>(_onSendVerificationCode);
    on<VerifyCodeEvent>(_onVerifyCode);
    on<ResendCodeEvent>(_onResendCode);

    on<GoogleSignInEvent>(_onGoogleSignIn);
  }

  // ---------------------------------------------------------------------------
  // EMAIL / PASSWORD SIGN-IN
  // ---------------------------------------------------------------------------

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        emailOrPhone: event.emailOrPhone,
        password: event.password,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN-UP
  // ---------------------------------------------------------------------------

Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
  emit(AuthLoading());
  try {
    final user = await _authRepository.signUp(
      name: event.name,              // ✅ ADD THIS LINE
      email: event.email,
      password: event.password,
    );
    emit(AuthSuccess(user));
  } catch (e) {
    emit(AuthFailure(e.toString()));
  }
}

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------------------------

  Future<void> _onForgotPassword(
      ForgotPasswordEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetEmailSent());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // PHONE / EMAIL VERIFICATION (CODE SENDING)
  // ---------------------------------------------------------------------------

  Future<void> _onSendVerificationCode(
      SendVerificationCodeEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      if (event.isSms) {
        await _authRepository.verifyPhoneNumber(
          phoneNumber: event.contact,
          onCodeSent: () => emit(CodeSentState()),
          onVerificationCompleted: (PhoneAuthCredential credential) async {
            // Sign in automatically if instant verification completes.
            await FirebaseAuth.instance.signInWithCredential(credential);
            emit(CodeVerificationSuccess());
          },
          onVerificationFailed: (msg) => emit(AuthFailure(msg)),
          onTimeout: (_) {},
        );
      } else {
        await _authRepository.sendEmailVerificationCode(event.contact);
        emit(CodeSentState());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // CODE VERIFICATION
  // ---------------------------------------------------------------------------

  Future<void> _onVerifyCode(
      VerifyCodeEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(CodeVerificationInProgress());
    try {
      if (event.isSms) {
        await _authRepository.signInWithSmsCode(event.code);
        emit(CodeVerificationSuccess());
      } else {
        final verified = await _authRepository.verifyEmailCode(
          email: event.email ?? '',
          code: event.code,
        );
        if (verified) {
          emit(CodeVerificationSuccess());
        } else {
          emit(
            CodeVerificationFailure(
              'The code you entered is incorrect or expired.',
            ),
          );
        }
      }
    } catch (e) {
      emit(CodeVerificationFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // RESEND CODE
  // ---------------------------------------------------------------------------

  Future<void> _onResendCode(
      ResendCodeEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(ResendCodeInProgress());
    try {
      if (event.isSms) {
        await _authRepository.verifyPhoneNumber(
          phoneNumber: event.contact,
          onCodeSent: () => emit(ResendCodeSuccess()),
          onVerificationCompleted: (_) {},
          onVerificationFailed: (msg) => emit(ResendCodeFailure(msg)),
          onTimeout: (_) {},
        );
      } else {
        await _authRepository.sendEmailVerificationCode(event.contact);
        emit(ResendCodeSuccess());
      }
    } catch (e) {
      emit(ResendCodeFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------------------------

  Future<void> _onGoogleSignIn(
      GoogleSignInEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final cred = await _authRepository.signInWithGoogle();
      emit(AuthSuccess(cred.user!));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}