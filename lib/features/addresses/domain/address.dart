import 'package:flutter/foundation.dart';

enum AddressLabel {
  home('Home'),
  work('Work'),
  other('Other');

  const AddressLabel(this.title);
  final String title;

  static AddressLabel fromName(String? name) => AddressLabel.values.firstWhere(
    (label) => label.name == name,
    orElse: () => AddressLabel.other,
  );
}

@immutable
class Address {
  final int? id;
  final AddressLabel label;
  final String fullName;
  final String phone;
  final String division;
  final String district;
  final String area;
  final String line1;
  final String? postalCode;
  final String? note;
  final bool isDefault;
  final DateTime updatedAt;

  const Address({
    this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.division,
    required this.district,
    required this.area,
    required this.line1,
    this.postalCode,
    this.note,
    this.isDefault = false,
    required this.updatedAt,
  });

  Address copyWith({
    int? id,
    String? phone,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label,
      fullName: fullName,
      phone: phone ?? this.phone,
      division: division,
      district: district,
      area: area,
      line1: line1,
      postalCode: postalCode,
      note: note,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get singleLine {
    final parts = [
      line1,
      area,
      district,
      division,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.join(', ');
  }
}
