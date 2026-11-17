import 'auth_provider.dart';

extension AuthOwner on AuthProvider {
  String? get userOwner {
    final id = userId;
    if (!isSignedIn || id == null) return null;
    return 'user:$id';
  }
}
