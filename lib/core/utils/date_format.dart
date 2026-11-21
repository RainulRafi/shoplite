const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// 7 Nov 2026
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';

String formatDateRange(DateTime from, DateTime to) {
  if (from.year != to.year) return '${formatDate(from)} to ${formatDate(to)}';
  final fromMonth = _months[from.month - 1];
  final toMonth = _months[to.month - 1];
  if (from.month != to.month) {
    return '${from.day} $fromMonth to ${to.day} $toMonth';
  }
  if (from.day == to.day) return '${from.day} $fromMonth';
  return '${from.day} to ${to.day} $toMonth';
}

String formatRelative(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return formatDate(at);
}
