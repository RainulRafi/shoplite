abstract class NotificationsRepository {
  Future<Set<String>> loadRead(String ownerId);

  Future<void> markRead(String ownerId, Iterable<String> keys);
}
