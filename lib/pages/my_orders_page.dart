import 'package:flutter/material.dart';
import '../main.dart' show MainScreen;
import '../services/api_service.dart';
import '../utils/order_status.dart';
import '../utils/order_utils.dart';
import 'order_details_page.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orders = await ApiService.getUserOrders();
      orders.sort((a, b) => OrderUtils.orderDate(b).compareTo(OrderUtils.orderDate(a)));
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openOrder(Map<String, dynamic> order) {
    final orderId = ApiService.mongoIdToString(order['_id']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(orderId: orderId, initialOrder: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'You haven\'t placed any orders yet.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final orderId = ApiService.mongoIdToString(
                            order['_id'],
                          );
                          final shortId = orderId.length > 8
                              ? orderId.substring(orderId.length - 8)
                              : orderId;
                          final items = OrderUtils.items(order);
                          final firstItemName =
                              items.isNotEmpty ? (items.first['name'] ?? '').toString() : '';
                          final extraCount = items.length > 1 ? items.length - 1 : 0;
                          final quantity = OrderUtils.totalQuantity(order);
                          final paymentMethod = (order['paymentMethod'] ?? '').toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openOrder(order),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #$shortId',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          OrderUtils.formatDate(order),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      extraCount > 0
                                          ? '$firstItemName and $extraCount more item${extraCount > 1 ? 's' : ''}'
                                          : firstItemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: $quantity  ·  $paymentMethod',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OrderStatusBadge(status: order['status']?.toString()),
                                        PaymentStatusBadge(status: order['paymentStatus']?.toString()),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '\$${OrderUtils.amount(order, 'grandTotal').toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: cs.secondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
