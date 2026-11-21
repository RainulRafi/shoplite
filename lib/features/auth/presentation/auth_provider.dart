import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_store.dart';
import '../data/auth_repository.dart';
import '../data/user_profile.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final TokenStore _store;

  AuthProvider(this._repository, this._store);

  static const String sessionEndedNotice =
      'Your session ended. Please sign in again.';

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;

  int? _userId;

  bool _profileLoading = false;
  ApiException? _profileError;
  bool _signingIn = false;
  String? _notice;

  int _session = 0;

  AuthStatus get status => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  UserProfile? get user => _user;
  int? get userId => _userId;
  bool get profileLoading => _profileLoading;
  ApiException? get profileError => _profileError;
  bool get signingIn => _signingIn;
  String? get notice => _notice;

  Future<void> restore() async {
    final tokens = await _store.read();
    if (tokens == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _userId = await _store.readUserId();
    _status = AuthStatus.signedIn;
    notifyListeners();
    await loadProfile();
  }

  Future<ApiException?> signIn(String username, String password) async {
    if (_signingIn || isSignedIn) return null;
    _signingIn = true;
    notifyListeners();

    try {
      final session = await _repository.login(
        username: username.trim(),
        password: password,
      );
      await _store.write(session.tokens);
      await _store.writeUserId(session.user.id);
      _session++;
      _user = session.user;
      _userId = session.user.id;
      _profileError = null;
      _profileLoading = false;
      _notice = null;
      _status = AuthStatus.signedIn;
      return null;
    } on ApiException catch (e) {
      return e;
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    if (_status != AuthStatus.signedIn || _profileLoading) return;

    final session = _session;
    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      final user = await _repository.fetchProfile();
      if (session == _session) {
        _user = user;

        if (_userId != user.id) {
          _userId = user.id;
          await _store.writeUserId(user.id);
        }
      }
    } on ApiException catch (e) {
      if (session == _session) _profileError = e;
    } finally {
      if (session == _session) _profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _session++;
    _user = null;
    _userId = null;
    _profileError = null;
    _profileLoading = false;
    _notice = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
    await _store.clear();
  }

  void handleSessionExpired() {
    if (_status != AuthStatus.signedIn) return;
    _session++;
    _user = null;
    _userId = null;
    _profileError = null;
    _profileLoading = false;
    _notice = sessionEndedNotice;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void dismissNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }
}
