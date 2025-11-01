import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State createState() => _CartScreenState();
}

class _CartScreenState extends State {
  static const brandBlue = Color(0xFF0E5AA6);

  // Dummy data (assets images). Replace later with Firestore stream.
  final List _items = [
    CartItem(
      id: '1',
      productId: 'p1',
      title: 'Panadol Cold & Flu',
      description:
          'an over-the-counter medication designed to relieve symptoms.',
      imageUrl: 'assets/images/panadol.png',
      price: 90,
      qty: 1,
    ),
    CartItem(
      id: '2',
      productId: 'p1',
      title: 'Panadol Cold & Flu',
      description:
          'an over-the-counter medication designed to relieve symptoms.',
      imageUrl: 'assets/images/panadol.png',
      price: 90,
      qty: 1,
    ),
    CartItem(
      id: '3',
      productId: 'p1',
      title: 'Panadol Cold & Flu',
      description:
          'an over-the-counter medication designed to relieve symptoms.',
      imageUrl: 'assets/images/panadol.png',
      price: 90,
      qty: 1,
    ),
    CartItem(
      id: '4',
      productId: 'p1',
      title: 'Panadol Cold & Flu',
      description:
          'an over-the-counter medication designed to relieve symptoms.',
      imageUrl: 'assets/images/panadol.png',
      price: 90,
      qty: 1,
    ),
  ];

  double get _total => _items.fold(0.0, (sum, e) => sum + (e.price * e.qty));

  void _incQty(int index) {
    setState(() => _items[index].qty++);
  }

  void _decQty(int index) {
    setState(() {
      if (_items[index].qty > 1) _items[index].qty--;
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _CartHeader(), // custom header with logo + back
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image from assets
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            item.imageUrl,
                            width: 120,
                            height: 95,
                            fit: BoxFit.cover,
                          ),
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
                                    'total : ${item.lineTotal.toStringAsFixed(0)}EG',
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
                                    onTap: () => _decQty(index),
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
                                    onTap: () => _incQty(index),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _removeItem(index),
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
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total Price : ${_total.toStringAsFixed(0)} EG',
                      style: theme.textTheme.titleLarge?.copyWith(
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
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _items.isEmpty ? null : () {},
                      child: const Text(
                        'Check out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Custom header with centered logo and left chevron back button.
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
          SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back chevron button (same shape as design)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: brandBlue,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                  ),
                ),
                // Center logo from assets
                Image.asset(
                  'assets/images/logo_medlink.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cart',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
