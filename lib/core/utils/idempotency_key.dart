import 'dart:math';

String newIdempotencyKey() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final random = Random.secure().nextInt(1 << 32).toRadixString(36);
  return '$time-$random';
}
