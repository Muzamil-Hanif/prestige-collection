import 'package:flutter/material.dart';

import '../main.dart' show MainScreen;
import '../services/safepay_service.dart';
import 'order_details_page.dart';

/// Web payment-return screen.
///
/// On the Flutter **web** build the `prestigecollection://` deep link can't
/// fire, so the backend callback redirects the browser to
/// `<web-origin>/#/payment-callback?status=...&order_id=...&tracker=...`. That
/// is a *fresh* page load — the checkout page (and its deep-link subscription)
/// is gone — so this standalone page resumes the verify → success/pending flow,
/// mirroring the in-app dialog on mobile (`checkout_page.dart`).
class PaymentCallbackPage extends StatefulWidget {
  final String? orderId;
  final String? tracker;
  final String status;

  const PaymentCallbackPage({
    super.key,
    required this.orderId,
    required this.tracker,
    required this.status,
  });

  @override
  State<PaymentCallbackPage> createState() => _PaymentCallbackPageState();
}

enum _CallbackState { verifying, success, pending, failed, cancelled }

class _PaymentCallbackPageState extends State<PaymentCallbackPage> {
  _CallbackState _state = _CallbackState.verifying;
  String? _note;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // The user cancelled on SafePay — nothing to verify.
    if (widget.status == 'cancelled') {
      setState(() => _state = _CallbackState.cancelled);
      return;
    }

    final orderId = widget.orderId;
    if (orderId == null || orderId.isEmpty) {
      setState(() {
        _state = _CallbackState.failed;
        _note = 'Missing order reference. Please check My Orders.';
      });
      return;
    }

    // The redirect carries the tracker (not the session requestId). The backend
    // already stored the tracker server-side and is webhook-first, so passing
    // the tracker for both the path fallback and the `?tracker=` query resolves
    // correctly even though the web build never saw the requestId.
    final result = await SafePayService.pollPaymentStatus(
      orderId: orderId,
      requestId: widget.tracker ?? 'web',
      tracker: widget.tracker,
      maxWait: const Duration(seconds: 40),
    );

    if (!mounted) return;
    setState(() {
      _note = result.note;
      if (result.success) {
        _state = _CallbackState.success;
      } else if (result.pending) {
        _state = _CallbackState.pending;
      } else {
        _state = _CallbackState.failed;
      }
    });
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _viewOrder() {
    final orderId = widget.orderId;
    if (orderId == null || orderId.isEmpty) {
      _goHome();
      return;
    }
    final nav = Navigator.of(context);
    // Replace this callback route with home, then open the order on top so
    // "back" returns the user to the app rather than this transient screen.
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    nav.push(
      MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _buildContent(cs),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    switch (_state) {
      case _CallbackState.verifying:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(cs.secondary),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Verifying payment...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );

      case _CallbackState.success:
        return _result(
          cs,
          icon: Icons.check_rounded,
          accent: cs.secondary,
          title: 'Payment Successful',
          message:
              'Thank you for your purchase. Your order has been placed successfully.',
          primaryLabel: 'View Order',
          onPrimary: _viewOrder,
          secondaryLabel: 'Continue Shopping',
          onSecondary: _goHome,
        );

      case _CallbackState.pending:
        return _result(
          cs,
          icon: Icons.hourglass_top_rounded,
          accent: cs.secondary,
          title: 'Confirming Payment',
          message: _note ??
              'Your payment is still being confirmed. It will appear in My Orders shortly — no need to pay again.',
          primaryLabel: 'Go to My Orders',
          onPrimary: _viewOrder,
          secondaryLabel: 'Continue Shopping',
          onSecondary: _goHome,
        );

      case _CallbackState.cancelled:
        return _result(
          cs,
          icon: Icons.close_rounded,
          accent: const Color(0xFFEF4444),
          title: 'Payment Cancelled',
          message:
              'Your payment was cancelled. You can try again from your cart or choose another method.',
          primaryLabel: 'Continue Shopping',
          onPrimary: _goHome,
        );

      case _CallbackState.failed:
        return _result(
          cs,
          icon: Icons.error_outline_rounded,
          accent: const Color(0xFFEF4444),
          title: 'Payment Not Completed',
          message: _note ??
              'We could not confirm your payment. Please try again or check My Orders.',
          primaryLabel: 'Continue Shopping',
          onPrimary: _goHome,
        );
    }
  }

  Widget _result(
    ColorScheme cs, {
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.15),
            border: Border.all(color: accent, width: 2.5),
          ),
          child: Icon(icon, size: 46, color: accent),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: cs.secondary,
              foregroundColor: cs.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              primaryLabel,
              style: TextStyle(
                color: cs.onSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.secondary,
                side: BorderSide(color: cs.secondary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
