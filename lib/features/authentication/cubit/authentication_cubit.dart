import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../services/authentication/authentication.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit() : super(const AuthenticationState.initial());

  final AuthenticationService _auth = AuthenticationService.instance;

  Future<void> restoreSession() async {
    emit(const AuthenticationState.loading());
    try {
      final user = await _auth.signIn();
      if (user == null) {
        emit(const AuthenticationState.unauthenticated());
      } else {
        emit(AuthenticationState.authenticated(user));
      }
    } catch (e) {
      emit(AuthenticationState.failure(e.toString()));
    }
  }

  Future<void> signIn() async {
    emit(const AuthenticationState.loading());
    try {
      final user = await _auth.signIn();
      if (user == null) {
        emit(const AuthenticationState.unauthenticated());
      } else {
        emit(AuthenticationState.authenticated(user));
      }
    } catch (e) {
      emit(AuthenticationState.failure(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthenticationState.loading());
    try {
      await _auth.signOut();
      emit(const AuthenticationState.unauthenticated());
    } catch (e) {
      emit(AuthenticationState.failure(e.toString()));
    }
  }
}


