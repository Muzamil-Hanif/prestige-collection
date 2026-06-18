import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart' show MainScreen;
import '../utils/order_status.dart';
import '../utils/order_utils.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  static final List<String> _statuses = OrderStatusHelper.selectableKeys;

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _updatingOrderId;

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
      final orders = await ApiService.getAllOrders();
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

  Map<String, dynamic> _customer(Map<String, dynamic> order) {
    final userId = order['userId'];
    if (userId is Map) return Map<String, dynamic>.from(userId);
    return {};
  }

  Future<void> _changeStatus(Map<String, dynamic> order, String status) async {
    final orderId = ApiService.mongoIdToString(order['_id']);
    if (orderId.isEmpty || status == order['status']) return;

    setState(() => _updatingOrderId = orderId);
    try {
      await ApiService.updateOrderStatus(orderId, status);
      if (!mounted) return;
      setState(() {
        order['status'] = status;
        _updatingOrderId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to ${OrderStatusHelper.label(status)}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingOrderId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
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
                      ? const Center(
                          child: Text(
                            'No orders received yet.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              final orderId = ApiService.mongoIdToString(order['_id']);
                              final shortId = orderId.length > 8
                                  ? orderId.substring(orderId.length - 8)
                                  : orderId;
                              final customer = _customer(order);
                              final items = (order['items'] as List?) ?? [];
                              final status = (order['status'] ?? '').toString();
                              final isUpdating = _updatingOrderId == orderId;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order #$shortId',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  customer['fullName']?.toString() ??
                                                      'Unknown customer',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (customer['email'] != null)
                                                  Text(
                                                    customer['email'].toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
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
                                      const SizedBox(height: 10),
                                      Text(
                                        '${items.length} item${items.length == 1 ? '' : 's'} · ${order['paymentMethod'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if ((order['walletPhoneNumber'] ?? '').toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Wallet #: ${order['walletPhoneNumber']}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if ((order['paymentTransactionId'] ?? '').toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Txn ID: ${order['paymentTransactionId']}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OrderStatusBadge(status: status),
                                          PaymentStatusBadge(
                                            status: order['paymentStatus']?.toString(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: cs.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: cs.outline),
                                              ),
                                              child: isUpdating
                                                  ? const Padding(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                      child: SizedBox(
                                                        height: 18,
                                                        width: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    )
                                                  // LayoutBuilder lets the popup menu be sized
                                                  // to exactly match the field's width, and
                                                  // PopupMenuPosition.under makes it open in the
                                                  // standard place: directly below the field
                                                  // instead of floating around the selected item.
                                                  : LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        return PopupMenuButton<String>(
                                                          position: PopupMenuPosition.under,
                                                          offset: const Offset(0, 4),
                                                          color: cs.primary,
                                                          elevation: 8,
                                                          padding: EdgeInsets.zero,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          constraints: BoxConstraints(
                                                            minWidth: constraints.maxWidth,
                                                            maxWidth: constraints.maxWidth,
                                                          ),
                                                          onSelected: (value) =>
                                                              _changeStatus(order, value),
                                                          itemBuilder: (context) => List.generate(
                                                            _statuses.length,
                                                            (i) {
                                                              final s = _statuses[i];
                                                              final isLast =
                                                                  i == _statuses.length - 1;
                                                              return PopupMenuItem<String>(
                                                                value: s,
                                                                padding: EdgeInsets.zero,
                                                                child: Container(
                                                                  width: double.infinity,
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                    horizontal: 16,
                                                                    vertical: 12,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    border: isLast
                                                                        ? null
                                                                        : const Border(
                                                                            bottom: BorderSide(
                                                                              color:
                                                                                  Colors.white24,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                  child: Text(
                                                                    OrderStatusHelper.label(s),
                                                                    style: TextStyle(
                                                                      color: s == status
                                                                          ? cs.secondary
                                                                          : Colors.white,
                                                                      fontWeight: s == status
                                                                          ? FontWeight.w700
                                                                          : FontWeight.w400,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          child: SizedBox(
                                                            width: double.infinity,
                                                            child: Padding(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 14,
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      _statuses.contains(status)
                                                                          ? OrderStatusHelper.label(status)
                                                                          : 'Select status',
                                                                      style: TextStyle(
                                                                        color: _statuses
                                                                                .contains(status)
                                                                            ? Colors.white
                                                                            : Colors.white70,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Icon(
                                                                    Icons.keyboard_arrow_down,
                                                                    color: cs.secondary,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '\$${((order['grandTotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
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
                              );
                            },
                          ),
                        ),
        ),
      ),
    );
  }
}
