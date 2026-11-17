import '../domain/address.dart';

abstract class AddressRepository {
  Future<List<Address>> loadAll(String ownerId);

  Future<int> insert(String ownerId, Address address);

  Future<void> update(String ownerId, Address address);

  Future<void> delete(String ownerId, int id);

  Future<void> setDefault(String ownerId, int id);
}
