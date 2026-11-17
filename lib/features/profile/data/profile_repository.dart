import '../domain/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileOverride?> load(String ownerId);
  Future<void> save(String ownerId, ProfileOverride override);
}
