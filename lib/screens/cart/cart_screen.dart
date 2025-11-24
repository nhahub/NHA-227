import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medilink_app/screens/orders/orders_screen.dart';

import '../../models/cart_item.dart';
import '../../services/cart_orders_service.dart';
import '../../services/payment_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const brandBlue = Color(0xFF0E5AA6);
  final _svc = CartOrdersService.instance;
  bool _processing = false;
  final Duration _tapCooldown = const Duration(seconds: 1);
  DateTime? _nextTapAllowed;

  bool get _isCoolingDown =>
      _nextTapAllowed != null && DateTime.now().isBefore(_nextTapAllowed!);

  void _startCooldown() {
    _nextTapAllowed = DateTime.now().add(_tapCooldown);
  }

  // Compute subtotal from current items
  double _subtotal(List items) =>
      items.fold(0.0, (sum, e) => sum + (e.price * e.qty));

  // Dev helper (remove when product flow is ready)
  Future _addSample() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await _svc.addOrIncItem(
      CartItem(
        id: 'panadol-1',
        productId: 'panadol-1',
        title: 'Panadol Cold & Flu',
        description:
            'an over-the-counter medication designed to relieve symptoms.',
        imageUrl: 'assets/images/panadol.png',
        price: 90,
        qty: 1,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sample item added')));
  }

  // Check payment method; open checkout if needed; then confirm and place order
  Future _onCheckout(List items) async {
    if (items.isEmpty) return;

    // 1) Check payment method
    bool hasPayment = false;
    try {
      hasPayment = await PaymentService.instance.hasAnyPaymentMethod();
    } catch (_) {
      hasPayment = false;
    }

    // 2) If no payment -> go add card and EXIT
    if (!hasPayment) {
      final added = await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      return; // important: nothing else happens on this tap
    }

    // 3) Has payment -> show summary dialog
    await _confirmAndPlaceOrder(items);
  }

  Future _confirmAndPlaceOrder(List items) async {
    final subtotal = _subtotal(items);
    const shipping = 20.0;
    final total = subtotal + (items.isEmpty ? 0 : shipping);
    final totalQty = items.fold<int>(
      0,
      (int sum, dynamic e) => sum + (e.qty as int),
    );

    final confirmed = await showDialog(
      context: context,
      builder: (context) {
        bool confirmDisabled = false;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Confirm Order'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _summaryRow('Items', '${totalQty}'),
                  const SizedBox(height: 6),
                  _summaryRow('Subtotal', '${subtotal.toStringAsFixed(0)} EG'),
                  _summaryRow('Shipping', '${shipping.toStringAsFixed(0)} EG'),
                  const Divider(height: 18),
                  _summaryRow(
                    'Total',
                    '${total.toStringAsFixed(0)} EG',
                    isBold: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: confirmDisabled
                      ? null
                      : () {
                          // optional: local cooldown before closing
                          setLocalState(() => confirmDisabled = true);
                          // If you prefer to show disabled state for 300ms:
                          // Future.delayed(const Duration(milliseconds: 300), () {
                          // Navigator.pop(context, true);
                          // });
                          Navigator.pop(context, true); // single click only
                        },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() => _processing = true);
      try {
        await _placeOrder(items);
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }
  }

  Future _placeOrder(List items) async {
    if (items.isEmpty) return;
    try {
      // Primary happy path
      final orderId = await _svc.placeOrderFromCart(
        shipping: 20,
        status: 'In Process',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      // Optional: navigate to orders
      // Navigator.of(context).pushReplacementNamed('/orders');
    } on FirebaseException catch (e, st) {
      // Log full details
      debugPrint('placeOrderFromCart failed: ${e.code}−${e.message}');
      debugPrint('$st');
      final created = await _svc.wasRecentOrderCreated();
      if (created && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'There was a problem placing the order try again later',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (e, st) {
      debugPrint('Unknown error placing order');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('There was a problem placing the order try again later'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _CartHeader(),
            Expanded(
              child: StreamBuilder<List<CartItem>>(
                stream: _svc.watchCart().map((e) => e.cast<CartItem>()),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  final items = snap.data ?? [];

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 84,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _addSample,
                            child: const Text('Add sample item'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _ImageFrom(item.imageUrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.price.toStringAsFixed(0)}EG',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: brandBlue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'total : ${(item.price * item.qty).toStringAsFixed(0)}EG',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: brandBlue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      RoundAssetButton(
                                        asset: 'assets/images/minus.png',
                                        activeAsset:
                                            'assets/images/minus_clicked.png',
                                        mode: PressMode.momentary,
                                        onTap: () => _svc.updateQty(
                                          item.productId,
                                          item.qty - 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.qty}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      RoundAssetButton(
                                        asset: 'assets/images/plus.png',
                                        activeAsset:
                                            'assets/images/plus_clicked.png',
                                        mode: PressMode.momentary,
                                        onTap: () => _svc.updateQty(
                                          item.productId,
                                          item.qty + 1,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () =>
                                            _svc.removeItem(item.productId),
                                        icon: Image.asset(
                                          'assets/images/delete.png',
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                        ),
                                        tooltip: 'Remove',
                                        splashRadius: 24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, indent: 24, endIndent: 24),

            // Footer: total + Checkout
            StreamBuilder<List<CartItem>>(
              stream: _svc.watchCart().map((e) => e.cast<CartItem>()),
              builder: (context, snap) {
                final items = snap.data ?? [];
                final subtotal = _subtotal(items);
                final shipping = items.isEmpty ? 0 : 20;
                final total = subtotal + shipping;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Price : ${total.toStringAsFixed(0)} EG',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 260,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              (items.isEmpty || _processing || _isCoolingDown)
                              ? null
                              : () {
                                  _startCooldown(); // start timeout immediately
                                  _onCheckout(items); // run your flow
                                }, // unchanged call
                          child: _processing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Check out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),

      // Dev: add sample product (remove when product flow is ready)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSample,
        backgroundColor: brandBlue,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add sample'),
      ),
    );
  }
}

// Summary row used in the confirm dialog
Widget _summaryRow(String label, String value, {bool isBold = false}) {
  final style = TextStyle(
    fontSize: isBold ? 16 : 14,
    fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
    color: Colors.black87,
  );
  return Row(
    children: [
      Text(label, style: style),
      const Spacer(),
      Text(value, style: style),
    ],
  );
}

// Header: logo + back + title (keeps your existing look)
class _CartHeader extends StatelessWidget {
  const _CartHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0E5AA6);
    return Container(
      color: const Color(0xFFF2F7FB),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          // Logo
          SizedBox(
            height: 56,
            child: Center(
              child: Image.asset(
                'assets/images/logo_medlink.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Back + Title
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: brandBlue,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => OrdersScreen())),
                  ),
                ),
                const Text(
                  'Cart',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// Asset or network image helper
class _ImageFrom extends StatelessWidget {
  final String pathOrUrl;
  const _ImageFrom(this.pathOrUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAsset = pathOrUrl.startsWith('assets/');
    final img = isAsset
        ? Image.asset(pathOrUrl, width: 120, height: 95, fit: BoxFit.cover)
        : Image.network(
            pathOrUrl,
            width: 120,
            height: 95,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 95,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: img);
  }
}

enum PressMode { momentary, toggle }

class RoundAssetButton extends StatefulWidget {
  final String asset; // default image
  final String activeAsset; // image to show when pressed/active
  final VoidCallback onTap;
  final double size;
  final Color background;
  final PressMode mode; // momentary = while pressed, toggle = stays after tap

  const RoundAssetButton({
    Key? key,
    required this.asset,
    required this.activeAsset,
    required this.onTap,
    this.size = 44,
    this.background = Colors.white,
    this.mode = PressMode.momentary,
  }) : super(key: key);

  @override
  State<RoundAssetButton> createState() => RoundAssetButtonState();
}

class RoundAssetButtonState extends State<RoundAssetButton> {
  bool _active = false;

  void _setPressed(bool v) {
    if (widget.mode == PressMode.momentary) {
      setState(() => _active = v);
    }
  }

  void _handleTap() {
    if (widget.mode == PressMode.toggle) {
      setState(() => _active = !_active);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = _active ? widget.activeAsset : widget.asset;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        child: Image.asset(imgPath, width: 24, height: 24, fit: BoxFit.contain),
      ),
    );
  }
}
