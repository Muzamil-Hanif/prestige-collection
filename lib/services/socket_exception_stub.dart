// Stub for SocketException on web where dart:io is unavailable.
// On native platforms, dart:io is used instead via the conditional import.
class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}
