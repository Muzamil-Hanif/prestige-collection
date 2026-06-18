import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/order_status.dart';
import '../utils/order_utils.dart';

/// Full-screen order detail + tracking experience, opened from My Orders.
/// Shows the purchased items, delivery information, payment details, and a
/// step-by-step fulfillment timeline (Daraz/Amazon-style).
class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  /// Data already available from the My Orders list, shown immediately
  /// while a fresh copy is fetched in the background so the status reflects
  /// the latest state ("track in real time").
  final Map<String, dynamic>? initialOrder;

  const OrderDetailsPage({super.key, required this.orderId, this.initialOrder});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _order;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final order = await ApiService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Keep showing whatever we already have; only surface the error
        // banner if we have nothing at all to display.
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _shortId(String id) => id.length > 8 ? id.substring(id.length - 8) : id;

  Widget _sectionCard(ColorScheme cs, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: cs.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemThumbnail(Map<String, dynamic> item) {
    final image = item['image'] as String?;
    if (image == null || image.isEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white70),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: image.startsWith('http')
          ? Image.network(
              ProductModel.toDisplayImageUrl(image),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white70),
              ),
            )
          : Image.asset(
              image,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white70),
              ),
            ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: emphasize ? 1 : 0.7),
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? Theme.of(context).colorScheme.secondary : Colors.white,
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final order = _order;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: order == null
          ? (_isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage ?? 'Order not found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadOrder, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ))
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(cs, order),
                    const SizedBox(height: 16),
                    if (OrderStatusHelper.isTerminalNegative(order['status']?.toString()))
                      _buildTerminalBanner(cs, order)
                    else
                      _sectionCard(
                        cs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(cs, 'Order Tracking', Icons.timeline_outlined),
                            _OrderTimeline(
                              cs: cs,
                              currentStatus: order['status']?.toString(),
                              paymentMethod: order['paymentMethod']?.toString(),
                            ),
                          ],
                        ),
                      ),
                    _buildItemsCard(cs, order),
                    _buildSummaryCard(cs, order),
                    _buildDeliveryCard(cs, order),
                    _buildPaymentCard(cs, order),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ColorScheme cs, Map<String, dynamic> order) {
    final orderId = ApiService.mongoIdToString(order['_id']);
    final color = OrderStatusHelper.color(cs, order['status']?.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(OrderStatusHelper.icon(order['status']?.toString()), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${_shortId(orderId)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on ${OrderUtils.formatDate(order, withTime: true)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          OrderStatusBadge(status: order['status']?.toString()),
        ],
      ),
    );
  }

  Widget _buildTerminalBanner(ColorScheme cs, Map<String, dynamic> order) {
    final status = order['status']?.toString();
    final color = OrderStatusHelper.color(cs, status);
    final isRefunded = OrderStatusHelper.isRefunded(status);
    return _sectionCard(
      cs,
      child: Row(
        children: [
          Icon(OrderStatusHelper.icon(status), color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OrderStatusHelper.label(status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  isRefunded
                      ? 'This order was refunded. The amount has been returned to your original payment method.'
                      : 'This order was cancelled and will not be fulfilled.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(ColorScheme cs, Map<String, dynamic> order) {
    final items = OrderUtils.items(order);
    return _sectionCard(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(cs, 'Items (${items.length})', Icons.shopping_bag_outlined),
          ...items.map((item) {
            final qty = (item['quantity'] as num?)?.toInt() ?? 0;
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemThumbnail(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: $qty  ·  \$${price.toStringAsFixed(2)} each',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(price * qty).toStringAsFixed(2)}',
                    style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, Map<String, dynamic> order) {
    return _sectionCard(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(cs, 'Order Summary', Icons.receipt_long_outlined),
          _summaryRow('Subtotal', '\$${OrderUtils.amount(order, 'totalPrice').toStringAsFixed(2)}'),
          _summaryRow('Shipping', '\$${OrderUtils.amount(order, 'shippingCost').toStringAsFixed(2)}'),
          const Divider(color: Colors.white24, height: 20),
          _summaryRow('Grand Total', '\$${OrderUtils.amount(order, 'grandTotal').toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(ColorScheme cs, Map<String, dynamic> order) {
    final address = order['shippingAddress'] is Map
        ? Map<String, dynamic>.from(order['shippingAddress'] as Map)
        : <String, dynamic>{};

    return _sectionCard(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(cs, 'Delivery Information', Icons.local_shipping_outlined),
          _infoLine(Icons.person_outline, (address['fullName'] ?? '').toString()),
          _infoLine(
            Icons.home_outlined,
            '${address['street'] ?? ''}, ${address['city'] ?? ''} ${address['zipCode'] ?? ''}'.trim(),
          ),
          _infoLine(Icons.phone_outlined, (address['phoneNumber'] ?? '').toString()),
          _infoLine(Icons.email_outlined, (address['email'] ?? '').toString()),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(ColorScheme cs, Map<String, dynamic> order) {
    final walletPhone = (order['walletPhoneNumber'] ?? '').toString();
    final transactionId = (order['paymentTransactionId'] ?? '').toString();

    return _sectionCard(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(cs, 'Payment Details', Icons.payment_outlined),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (order['paymentMethod'] ?? '').toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              PaymentStatusBadge(status: order['paymentStatus']?.toString()),
            ],
          ),
          if (walletPhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoLine(Icons.phone_android_outlined, 'Wallet Number: $walletPhone'),
          ],
          if (transactionId.isNotEmpty) ...[
            const SizedBox(height: 2),
            _infoLine(Icons.confirmation_number_outlined, 'Transaction ID: $transactionId'),
          ],
        ],
      ),
    );
  }
}

/// Vertical step tracker — each completed/current/future stage in the order
/// lifecycle, connected by a line. Mirrors the order-tracking UI common to
/// Daraz/Amazon-style marketplaces.
class _OrderTimeline extends StatelessWidget {
  final ColorScheme cs;
  final String? currentStatus;
  final String? paymentMethod;

  const _OrderTimeline({
    required this.cs,
    required this.currentStatus,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatusHelper.timelineFor(paymentMethod);
    final currentIndex = OrderStatusHelper.timelineIndexFor(currentStatus, paymentMethod);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isDone = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isActive = isDone || isCurrent;
        final isLast = index == steps.length - 1;

        final dotColor = isActive ? cs.secondary : Colors.white.withValues(alpha: 0.25);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? dotColor.withValues(alpha: 0.18) : Colors.transparent,
                      border: Border.all(color: dotColor, width: 1.6),
                    ),
                    child: Icon(
                      isDone ? Icons.check : step.icon,
                      size: 15,
                      color: dotColor,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDone ? cs.secondary : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 4),
                  child: Text(
                    step.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
