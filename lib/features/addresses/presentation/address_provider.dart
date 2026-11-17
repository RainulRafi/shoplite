import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/data_status.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/address_repository.dart';
import '../domain/address.dart';
import '../domain/address_validators.dart';
import '../../../core/validation/bd_phone.dart';

enum AddressResult { saved, invalid, limitReached, notSignedIn, failed }

class AddressProvider extends ChangeNotifier {
  final AddressRepository _repository;
  final AuthProvider _auth;

  AddressProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  DataStatus _status = DataStatus.ready;
  List<Address> _addresses = const [];
  bool _disposed = false;

  DataStatus get status => _status;
  List<Address> get addresses => _addresses;
  bool get canAddMore => _addresses.length < AddressValidators.maxAddresses;

  Address? get defaultAddress {
    for (final a in _addresses) {
      if (a.isDefault) return a;
    }
    return null;
  }

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next == _owner) return;
    _owner = next;
    unawaited(_loadFor(next));
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _addresses = const [];
    _status = owner == null ? DataStatus.ready : DataStatus.loading;
    _notify();
    if (owner == null) return;

    try {
      final list = await _repository.loadAll(owner);
      if (generation != _generation) return;
      _addresses = list;
      _status = DataStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load addresses: $e');
      _status = DataStatus.error;
    }
    _notify();
  }

  void retry() {
    if (_status != DataStatus.error) return;
    unawaited(_loadFor(_owner));
  }

  Future<AddressResult> save(Address draft) async {
    final owner = _owner;
    if (owner == null) return AddressResult.notSignedIn;
    if (_status != DataStatus.ready) return AddressResult.failed;
    if (AddressValidators.validateAll(draft).isNotEmpty) {
      return AddressResult.invalid;
    }

    final isNew = draft.id == null;
    if (isNew && !canAddMore) return AddressResult.limitReached;

    final clean = draft.copyWith(
      phone: normalizeBdPhone(draft.phone) ?? draft.phone,
      updatedAt: DateTime.now(),
    );

    try {
      if (isNew) {
        await _repository.insert(owner, clean);
      } else {
        await _repository.update(owner, clean);
      }
      await _reload(owner);
      return AddressResult.saved;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not save the address: $e');
      return AddressResult.failed;
    }
  }

  Future<bool> setDefault(int id) async {
    final owner = _owner;
    if (owner == null) return false;
    try {
      await _repository.setDefault(owner, id);
      await _reload(owner);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not set the default address: $e');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    final owner = _owner;
    if (owner == null) return false;
    try {
      await _repository.delete(owner, id);
      await _reload(owner);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not delete the address: $e');
      return false;
    }
  }

  Future<void> _reload(String owner) async {
    final list = await _repository.loadAll(owner);
    if (owner != _owner) return;
    _addresses = list;
    _notify();
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
