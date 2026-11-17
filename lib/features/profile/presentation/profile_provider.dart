import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/data_status.dart';
import '../../../core/validation/bd_phone.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/profile_repository.dart';
import '../domain/profile_data.dart';
import '../domain/profile_validators.dart';

enum ProfileResult { saved, invalid, notSignedIn, failed }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  final AuthProvider _auth;

  ProfileProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  DataStatus _status = DataStatus.ready;
  ProfileOverride? _override;
  bool _disposed = false;

  DataStatus get status => _status;

  EffectiveProfile? get effective {
    final base = _auth.user;
    if (base == null) return null;
    return EffectiveProfile.merge(base, _override);
  }

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next != _owner) {
      _owner = next;
      unawaited(_loadFor(next));
      return;
    }

    _notify();
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;
    _override = null;
    _status = owner == null ? DataStatus.ready : DataStatus.loading;
    _notify();
    if (owner == null) return;

    try {
      final loaded = await _repository.load(owner);
      if (generation != _generation) return;
      _override = loaded;
      _status = DataStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load profile changes: $e');
      _status = DataStatus.ready;
    }
    _notify();
  }

  Future<ProfileResult> save({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final owner = _owner;
    if (owner == null) return ProfileResult.notSignedIn;

    if (ProfileValidators.firstName(firstName) != null ||
        ProfileValidators.lastName(lastName) != null ||
        ProfileValidators.phone(phone) != null) {
      return ProfileResult.invalid;
    }

    final trimmedPhone = phone.trim();
    final saved = ProfileOverride(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: trimmedPhone.isEmpty
          ? ''
          : (normalizeBdPhone(trimmedPhone) ?? trimmedPhone),
    );

    try {
      await _repository.save(owner, saved);
      if (owner != _owner) return ProfileResult.saved;
      _override = saved;
      _notify();
      return ProfileResult.saved;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not save the profile: $e');
      return ProfileResult.failed;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
