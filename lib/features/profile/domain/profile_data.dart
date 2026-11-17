import 'package:flutter/foundation.dart';

import '../../auth/data/user_profile.dart';

@immutable
class ProfileOverride {
  final String firstName;
  final String lastName;
  final String phone;

  const ProfileOverride({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });
}

@immutable
class EffectiveProfile {
  final int id;
  final String username;
  final String email;
  final String image;
  final String firstName;
  final String lastName;
  final String phone;

  const EffectiveProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.image,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  factory EffectiveProfile.merge(UserProfile base, ProfileOverride? override) {
    return EffectiveProfile(
      id: base.id,
      username: base.username,
      email: base.email,
      image: base.image,
      firstName: override?.firstName ?? base.firstName,
      lastName: override?.lastName ?? base.lastName,
      phone: override?.phone ?? '',
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final both = (first + last).toUpperCase();
    if (both.isNotEmpty) return both;
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }
}
