import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/profile/data/sqlite_profile_repository.dart';
import 'package:shoplite/features/profile/domain/profile_validators.dart';
import 'package:shoplite/features/profile/presentation/profile_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/test_support.dart';

void main() {
  group('validators', () {
    test('the first name is required, the others are optional', () {
      expect(ProfileValidators.firstName(''), isNotNull);
      expect(ProfileValidators.firstName('  '), isNotNull);
      expect(ProfileValidators.firstName('Emily'), isNull);
      expect(ProfileValidators.lastName(''), isNull);
      expect(ProfileValidators.phone(''), isNull);
      expect(ProfileValidators.phone('01712345678'), isNull);
      expect(ProfileValidators.phone('12345'), isNotNull);
    });
  });

  group('provider', () {
    late Database db;
    late SqliteProfileRepository repo;
    late AuthRig rig;
    late ProfileProvider profile;

    setUp(() async {
      db = await openTestDatabase();
      repo = SqliteProfileRepository(() async => db);
      rig = AuthRig();
      await rig.auth.restore();
      profile = ProfileProvider(repo, rig.auth);
    });

    tearDown(() async {
      profile.dispose();
      rig.dispose();
      await db.close();
    });

    test('a guest has no profile', () {
      expect(profile.effective, isNull);
    });

    test('with no changes, the server name is shown', () async {
      await rig.signIn();
      await waitUntil(() => profile.status == DataStatus.ready);

      expect(profile.effective!.fullName, 'Emily Johnson');
      expect(profile.effective!.phone, '');
      expect(profile.effective!.email, 'emily@x.test');
    });

    test(
      'saved changes replace the name and phone but not the email or username',
      () async {
        await rig.signIn();
        await waitUntil(() => profile.status == DataStatus.ready);

        final result = await profile.save(
          firstName: ' Emi ',
          lastName: '',
          phone: '+880 1712-345678',
        );

        expect(result, ProfileResult.saved);
        expect(profile.effective!.fullName, 'Emi');
        expect(profile.effective!.phone, '01712345678');
        expect(profile.effective!.email, 'emily@x.test');
        expect(profile.effective!.username, 'emilys');
      },
    );

    test('invalid input is refused and nothing changes', () async {
      await rig.signIn();
      await waitUntil(() => profile.status == DataStatus.ready);

      expect(
        await profile.save(firstName: '', lastName: '', phone: ''),
        ProfileResult.invalid,
      );
      expect(
        await profile.save(firstName: 'Emi', lastName: '', phone: '123'),
        ProfileResult.invalid,
      );

      expect(profile.effective!.fullName, 'Emily Johnson');
    });

    test(
      'the changes survive a restart, and each person has their own',
      () async {
        await rig.signIn();
        await waitUntil(() => profile.status == DataStatus.ready);
        await profile.save(firstName: 'Emi', lastName: 'J', phone: '');

        final reopened = ProfileProvider(repo, rig.auth);
        await waitUntil(() => reopened.status == DataStatus.ready);
        expect(reopened.effective!.fullName, 'Emi J');
        reopened.dispose();

        await rig.auth.signOut();
        await rig.signIn(testUser2);
        await waitUntil(() => profile.status == DataStatus.ready);
        expect(profile.effective!.fullName, 'Michael Williams');
      },
    );

    test('saving while signed out does nothing', () async {
      expect(
        await profile.save(firstName: 'Emi', lastName: '', phone: ''),
        ProfileResult.notSignedIn,
      );
    });
  });
}
