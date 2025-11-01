import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cart_item.dart';
import '../../services/cart_orders_service.dart';
import 'checkout_screen.dart';
import '../../services/payment_service.dart';


class CartScreen extends StatefulWidget {
const CartScreen({Key? key}) : super(key: key);

@override
State createState() => _CartScreenState();
}

class _CartScreenState extends State {
static const brandBlue = Color(0xFF0E5AA6);
final _svc = CartOrdersService.instance;

// Compute subtotal from current items
double _subtotal(List items) =>
items.fold(0.0, (sum, e) => sum + (e.price * e.qty));

// Temporary helper while product flow isn’t ready
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
ScaffoldMessenger.of(context)
.showSnackBar(const SnackBar(content: Text('Sample item added')));
}

Future _placeOrder(List items) async {
if (items.isEmpty) return;
try {
final orderId = await _svc.placeOrderFromCart(
shipping: 20,
status: 'In Process',
);
if (!mounted) return;

// Feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Order placed (#$orderId)')),
);

// Go to My Orders list
Navigator.of(context).pushReplacementNamed('/orders');
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context)
.showSnackBar(SnackBar(content: Text('Error: $e')));
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
stream: _svc.watchCart().cast<List<CartItem>>(),
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
                      Icon(Icons.shopping_cart_outlined,
                          size: 84, color: Colors.grey.shade400),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  _RoundIconButton(
                                    icon: Icons.remove,
                                    onTap: () => _svc
                                        .updateQty(item.productId, item.qty - 1),
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
                                  _RoundIconButton(
                                    icon: Icons.add,
                                    onTap: () => _svc
                                        .updateQty(item.productId, item.qty + 1),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () =>
                                        _svc.removeItem(item.productId),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                    tooltip: 'Remove',
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
        StreamBuilder<List<CartItem>>(
                  stream: _svc.watchCart().cast<List<CartItem>>(),
                  builder: (context, snap) {
            final items = snap.data ?? [];
            final subtotal = _subtotal(items);
            final shipping = items.isEmpty ? 0 : 20;
            final total = subtotal + shipping;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                          onPressed: items.isEmpty ? null : () => _placeOrder(items),
                      child: const Text(
                        'Check out',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
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
  floatingActionButton: FloatingActionButton.extended(
    onPressed: _addSample,
    backgroundColor: brandBlue,
    icon: const Icon(Icons.add_shopping_cart),
    label: const Text('Add sample'),
  ),
);
}
}

// Header: logo centered + back chevron + title
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
icon: const Icon(Icons.chevron_left,
color: brandBlue, size: 28),
onPressed: () => Navigator.of(context).maybePop(),
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

// Helper: asset or network image
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
return ClipRRect(
borderRadius: BorderRadius.circular(8),
child: img,
);
}
}

class _RoundIconButton extends StatelessWidget {
final IconData icon;
final VoidCallback onTap;
const _RoundIconButton({required this.icon, required this.onTap, Key? key})
: super(key: key);

@override
Widget build(BuildContext context) {
const brandBlue = Color(0xFF0E5AA6);
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(22),
child: Container(
width: 44,
height: 44,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: brandBlue, width: 2),
color: Colors.white,
),
child: Icon(icon, color: brandBlue),
),
);

}
}
