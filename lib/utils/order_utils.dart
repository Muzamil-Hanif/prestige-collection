/// Small shared helpers for reading fields off the raw order maps returned
/// by the backend (`Map<String, dynamic>`), used by My Orders, Order
/// Details, and the admin orders screen.
class OrderUtils {
  OrderUtils._();

  static DateTime orderDate(Map<String, dynamic> order) {
    final raw = order['createdAt'];
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime(1970);
    return DateTime(1970);
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "16 Jun 2026" or, with [withTime], "16 Jun 2026, 03:45 PM".
  static String formatDate(Map<String, dynamic> order, {bool withTime = false}) {
    final date = orderDate(order);
    if (date.year == 1970) return '';
    final base = '${date.day} ${_months[date.month - 1]} ${date.year}';
    if (!withTime) return base;

    final hour24 = date.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$base, $hour12:$minute $period';
  }

  static List<Map<String, dynamic>> items(Map<String, dynamic> order) {
    final raw = order['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Total units across every line item (sum of quantities), used for the
  /// "Quantity" column in the order list.
  static int totalQuantity(Map<String, dynamic> order) {
    var total = 0;
    for (final item in items(order)) {
      total += (item['quantity'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  static double amount(Map<String, dynamic> order, String key) =>
      (order[key] as num?)?.toDouble() ?? 0.0;
}
