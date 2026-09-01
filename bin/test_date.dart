void main() {
  final supabaseStr = '2026-09-05 00:00:00+00';
  try {
     final dt = DateTime.parse(supabaseStr);
     print('Success: $dt');
  } catch (e) {
     print('Failed: $e');
  }
}
