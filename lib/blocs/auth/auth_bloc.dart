import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<SignInEvent>(_signIn);
    on<SignUpEvent>(_signUp);
    on<ForgotPasswordEvent>(_forgotPassword);
    on<SignOutEvent>(_signOut);
  }

  Future<void> _signIn(SignInEvent event, Emitter<AuthState> emit) async {
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

  Future<void> _signUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(email: event.email, password: event.password);
      // Optionally save user name in Firestore or update profile here
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _forgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetEmailSent());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _signOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
    emit(AuthInitial());
  }
}