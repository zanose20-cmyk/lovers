class DateHelper {
  static String relative(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).round()} أ';
    return 'منذ ${(diff.inDays / 30).round()} ش';
  }
}
