import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/responsive.dart';

/// Allows optional leading `+` and digits only; `+` must be first if present.
class _PhoneDigitsPlusFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final buf = StringBuffer();
    for (var i = 0; i < newValue.text.length; i++) {
      final c = newValue.text[i];
      if (c == '+') {
        if (buf.isEmpty) buf.write(c);
      } else if (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) {
        buf.write(c);
      }
    }
    final text = buf.toString();
    if (text == oldValue.text) return oldValue;

    var offset = newValue.selection.baseOffset;
    if (offset > text.length) offset = text.length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;
  final Function() onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalPrice,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  String _selectedPaymentMethod = 'Credit Card';
  final double _shippingCost = 10.00;
  bool _isPlacingOrder = false;
  int _currentStep = 0;

  /// After Address step fails validation, re-validate on change so fixed fields clear.
  bool _addressLiveValidation = false;

  static const _stepLabels = ['Address', 'Checkout', 'Payment'];
  static const _connectorHints = ['Go To Checkout', 'Choose Payment Method'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  double get _grandTotal => widget.totalPrice + _shippingCost;

  static final _phoneE164Pattern = RegExp(r'^\+?[0-9]{7,15}$');

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your phone number';
    if (!_phoneE164Pattern.hasMatch(v)) {
      return 'Use 7–15 digits, optional + at the start';
    }
    return null;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.7)),
      filled: true,
      fillColor: cs.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.secondary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 1.2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  BoxDecoration _cardDecoration(ColorScheme cs) {
    return BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
    );
  }

  void _placeOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final shippingAddress = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'street': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'zipCode': _zipController.text.trim(),
      };

      await ApiService.createOrder(
        items: widget.cartItems,
        totalPrice: widget.totalPrice,
        shippingCost: _shippingCost,
        grandTotal: _grandTotal,
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        _showOrderSuccessDialog(Theme.of(context).colorScheme);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onPrimaryAction() {
    FocusScope.of(context).unfocus();
    if (_currentStep < 2) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() {
          _currentStep++;
          if (_currentStep > 0) _addressLiveValidation = false;
        });
      } else if (_currentStep == 0) {
        setState(() => _addressLiveValidation = true);
      }
    } else {
      _placeOrder();
    }
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showOrderSuccessDialog(ColorScheme cs) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final topAccent =
            Color.lerp(cs.surfaceContainerHighest, cs.secondary, 0.12) ??
            cs.surfaceContainerHighest;
        final bottomDeep =
            Color.lerp(cs.surface, Colors.black, 0.28) ?? cs.surface;

        const dialogRadius = 22.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(dialogRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [topAccent, cs.surfaceContainerHighest, bottomDeep],
                  stops: const [0.0, 0.42, 1.0],
                ),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: cs.secondary.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(
                                  cs.surfaceContainerHighest,
                                  cs.secondary,
                                  0.2,
                                ) ??
                                cs.surfaceContainerHighest,
                            Color.lerp(
                                  cs.surfaceContainerHighest,
                                  Colors.black,
                                  0.12,
                                ) ??
                                cs.surfaceContainerHighest,
                          ],
                        ),
                        border: Border.all(color: cs.secondary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: cs.secondary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 44,
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Order placed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thank you for your purchase. Your order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          widget.onOrderPlaced();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: cs.secondary,
                          foregroundColor: cs.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: cs.onSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const statusBarLight = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarLight,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerHighest,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Checkout'),
          foregroundColor: cs.onSurface,
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: statusBarLight,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(cs.surfaceContainerHighest, Colors.black, 0.12) ??
                        cs.surfaceContainerHighest,
                    cs.surfaceContainerHighest,
                    Color.lerp(cs.surface, Colors.black, 0.25) ?? cs.surface,
                  ],
                ),
              ),
              child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHorizontalStepper(cs),
                  Expanded(
                    child: IndexedStack(
                      index: _currentStep,
                      children: [
                        _buildAddressStep(cs),
                        _buildCheckoutStep(cs),
                        _buildPaymentStep(cs),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            14 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(cs.surfaceContainerHighest, Colors.black, 0.08),
            border: Border(
              top: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _onBack,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: cs.outline.withValues(alpha: 0.65),
                        ),
                        foregroundColor: cs.onSurface.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondary,
                      disabledBackgroundColor: cs.secondary.withValues(
                        alpha: 0.55,
                      ),
                      foregroundColor: cs.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPlacingOrder && _currentStep == 2
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: cs.onSecondary,
                            ),
                          )
                        : Text(
                            _currentStep < 2 ? 'Next' : 'Place Order',
                            style: TextStyle(
                              color: cs.onSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalStepper(ColorScheme cs) {
    const icons = [
      Icons.location_on_outlined,
      Icons.shopping_cart_outlined,
      Icons.payment_outlined,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _stepColumn(
              cs: cs,
              stepIndex: 0,
              label: _stepLabels[0],
              icon: icons[0],
            ),
          ),
          Expanded(
            flex: 3,
            child: _connectorColumn(
              cs: cs,
              hint: _connectorHints[0],
              lineActive: _currentStep >= 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: _stepColumn(
              cs: cs,
              stepIndex: 1,
              label: _stepLabels[1],
              icon: icons[1],
            ),
          ),
          Expanded(
            flex: 3,
            child: _connectorColumn(
              cs: cs,
              hint: _connectorHints[1],
              lineActive: _currentStep >= 2,
            ),
          ),
          Expanded(
            flex: 2,
            child: _stepColumn(
              cs: cs,
              stepIndex: 2,
              label: _stepLabels[2],
              icon: icons[2],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepColumn({
    required ColorScheme cs,
    required int stepIndex,
    required String label,
    required IconData icon,
  }) {
    final isPast = stepIndex < _currentStep;
    final isCurrent = stepIndex == _currentStep;
    final isActive = isPast || isCurrent;
    final accent = cs.secondary;
    final muted = cs.onSurface.withValues(alpha: 0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DottedStepRing(
          size: 48,
          color: isActive ? accent : muted,
          strokeWidth: 2.2,
          dashLength: 4,
          dashGap: 3.5,
          child: Icon(icon, size: 22, color: isActive ? accent : muted),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? accent : muted,
          ),
        ),
      ],
    );
  }

  Widget _connectorColumn({
    required ColorScheme cs,
    required String hint,
    required bool lineActive,
  }) {
    final accent = cs.secondary;
    final mutedLine = cs.onSurface.withValues(alpha: 0.22);
    final hintColor = cs.onSurface.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: lineActive ? accent : mutedLine,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(cs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              cs,
              'Shipping Address',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              cursorColor: cs.onSurface,
              style: TextStyle(color: cs.onSurface),
              decoration: _fieldDecoration(
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              onChanged: (_) {
                if (_addressLiveValidation) {
                  _formKey.currentState?.validate();
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              cursorColor: cs.onSurface,
              style: TextStyle(color: cs.onSurface),
              decoration: _fieldDecoration(
                label: 'Email',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_addressLiveValidation) {
                  _formKey.currentState?.validate();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              cursorColor: cs.onSurface,
              style: TextStyle(color: cs.onSurface),
              decoration: _fieldDecoration(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [_PhoneDigitsPlusFormatter()],
              onChanged: (_) {
                if (_addressLiveValidation) {
                  _formKey.currentState?.validate();
                }
              },
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              cursorColor: cs.onSurface,
              style: TextStyle(color: cs.onSurface),
              decoration: _fieldDecoration(
                label: 'Street Address',
                icon: Icons.home_outlined,
              ),
              maxLines: 2,
              onChanged: (_) {
                if (_addressLiveValidation) {
                  _formKey.currentState?.validate();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    cursorColor: cs.onSurface,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _fieldDecoration(
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    onChanged: (_) {
                      if (_addressLiveValidation) {
                        _formKey.currentState?.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    cursorColor: cs.onSurface,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _fieldDecoration(
                      label: 'ZIP Code',
                      icon: Icons.pin_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_addressLiveValidation) {
                        _formKey.currentState?.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ZIP';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(cs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              cs,
              'Order Summary',
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              separatorBuilder: (_, _) => Divider(
                height: 20,
                color: cs.outline.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item['quantity']}',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(((item['price'] as double?) ?? 0.0) * (item['quantity'] as int)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            Divider(height: 28, color: cs.outline.withValues(alpha: 0.35)),
            _buildSummaryRow(
              cs,
              'Subtotal',
              '\$${widget.totalPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              cs,
              'Shipping',
              '\$${_shippingCost.toStringAsFixed(2)}',
            ),
            Divider(height: 24, color: cs.outline.withValues(alpha: 0.35)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep(ColorScheme cs) {
    final radioTheme = RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return cs.secondary;
        }
        return cs.onSurface.withValues(alpha: 0.45);
      }),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: _cardDecoration(cs),
        child: Theme(
          data: Theme.of(context).copyWith(radioTheme: radioTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _buildSectionHeader(
                  cs,
                  'Payment Method',
                  Icons.payment_outlined,
                ),
              ),
              RadioListTile<String>(
                title: Text(
                  'Credit Card',
                  style: TextStyle(color: cs.onSurface),
                ),
                subtitle: Text(
                  'Visa, Mastercard, Amex',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                value: 'Credit Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Debit Card',
                  style: TextStyle(color: cs.onSurface),
                ),
                subtitle: Text(
                  'Visa, Mastercard',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                value: 'Debit Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text('PayPal', style: TextStyle(color: cs.onSurface)),
                subtitle: Text(
                  'Pay with PayPal account',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                value: 'PayPal',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Cash on Delivery',
                  style: TextStyle(color: cs.onSurface),
                ),
                subtitle: Text(
                  'Pay when you receive',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                value: 'Cash on Delivery',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: cs.secondary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ColorScheme cs, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DottedStepRing extends StatelessWidget {
  const _DottedStepRing({
    required this.size,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.child,
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DottedOvalPainter(
              color: color,
              strokeWidth: strokeWidth,
              dashLength: dashLength,
              dashGap: dashGap,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DottedOvalPainter extends CustomPainter {
  _DottedOvalPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()..addOval(rect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        final extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedOvalPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}
