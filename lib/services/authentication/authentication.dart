import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthenticationService {
  AuthenticationService._();
  static final AuthenticationService instance = AuthenticationService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    final user = await _googleSignIn.signInSilently();
    if (user != null) return user;
    return _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    await _googleSignIn.signOut();
  }

  Future<Map<String, String>> authHeaders() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw StateError('Not signed in');
    }
    return await account.authHeaders;
  }

  Future<http.Client> authenticatedClient() async {
    final headers = await authHeaders();
    return _GoogleAuthClient(headers);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}


