import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/addresses/domain/address.dart';
import 'package:shoplite/features/addresses/domain/address_validators.dart';
import 'package:shoplite/features/addresses/presentation/address_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/test_support.dart';

Address _draft({String name = 'Rahim Uddin', String phone = '01712345678'}) =>
    Address(
      label: AddressLabel.home,
      fullName: name,
      phone: phone,
      division: 'Dhaka',
      district: 'Dhaka',
      area: 'Mirpur',
      line1: 'House 12, Road 4',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

void main() {
  late Database db;
  late AuthRig rig;
  late AddressProvider provider;

  setUp(() async {
    db = await openTestDatabase();
    rig = AuthRig();
    await rig.auth.restore();
    provider = AddressProvider(
      SqliteAddressRepository(() async => db),
      rig.auth,
    );
  });

  tearDown(() async {
    provider.dispose();
    rig.dispose();
    await db.close();
  });

  Future<void> signInAndWait([user = testUser]) async {
    await rig.signIn(user);
    await waitUntil(() => provider.status == DataStatus.ready);
  }

  test('a guest has no addresses and cannot save one', () async {
    expect(provider.status, DataStatus.ready);
    expect(provider.addresses, isEmpty);
    expect(await provider.save(_draft()), AddressResult.notSignedIn);
  });

  test('the first saved address becomes the default', () async {
    await signInAndWait();

    expect(await provider.save(_draft()), AddressResult.saved);

    expect(provider.addresses.length, 1);
    expect(provider.defaultAddress!.fullName, 'Rahim Uddin');
  });

  test('an invalid address is refused and nothing is saved', () async {
    await signInAndWait();

    expect(await provider.save(_draft(phone: '123')), AddressResult.invalid);

    expect(provider.addresses, isEmpty);
  });

  test('the phone is stored in its normal form', () async {
    await signInAndWait();

    await provider.save(_draft(phone: '+880 1712-345678'));

    expect(provider.addresses.single.phone, '01712345678');
  });

  test('the eleventh address is refused', () async {
    await signInAndWait();
    for (var i = 0; i < AddressValidators.maxAddresses; i++) {
      expect(
        await provider.save(_draft(name: 'Person $i')),
        AddressResult.saved,
      );
    }

    expect(provider.canAddMore, isFalse);
    expect(
      await provider.save(_draft(name: 'One too many')),
      AddressResult.limitReached,
    );
    expect(provider.addresses.length, AddressValidators.maxAddresses);
  });

  test('setting a default and deleting work through the provider', () async {
    await signInAndWait();
    expect(await provider.save(_draft(name: 'Alice')), AddressResult.saved);
    expect(await provider.save(_draft(name: 'Bobby')), AddressResult.saved);
    final bobby = provider.addresses.firstWhere((a) => a.fullName == 'Bobby');

    expect(await provider.setDefault(bobby.id!), isTrue);
    expect(provider.defaultAddress!.fullName, 'Bobby');

    expect(await provider.delete(bobby.id!), isTrue);
    expect(provider.addresses.map((a) => a.fullName), ['Alice']);
    expect(provider.defaultAddress!.fullName, 'Alice');
  });

  test('editing keeps the id and changes the data', () async {
    await signInAndWait();
    await provider.save(_draft(name: 'Old name'));
    final saved = provider.addresses.single;

    final result = await provider.save(
      Address(
        id: saved.id,
        label: saved.label,
        fullName: 'New name',
        phone: saved.phone,
        division: saved.division,
        district: saved.district,
        area: saved.area,
        line1: saved.line1,
        isDefault: saved.isDefault,
        updatedAt: DateTime.now(),
      ),
    );

    expect(result, AddressResult.saved);
    expect(provider.addresses.single.fullName, 'New name');
    expect(provider.addresses.single.id, saved.id);
  });

  test('each person sees only their own addresses on a shared phone', () async {
    await signInAndWait();
    await provider.save(_draft(name: 'Emily home'));

    await rig.auth.signOut();
    expect(provider.addresses, isEmpty); // অন্যজনের ঠিকানা দেখা যায় না

    await signInAndWait(testUser2);
    expect(provider.addresses, isEmpty);
    await provider.save(_draft(name: 'Michael home'));

    await rig.auth.signOut();
    await signInAndWait(); // Emily আবার
    expect(provider.addresses.map((a) => a.fullName), ['Emily home']);
  });
}
