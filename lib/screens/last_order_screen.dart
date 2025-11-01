import 'package:flutter/material.dart';
import '../services/cart_orders_service.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class LastOrderScreen extends StatelessWidget {
LastOrderScreen({Key? key}) : super(key: key);

final _svc = CartOrdersService.instance;

@override
Widget build(BuildContext context) {
const bg = Color(0xFFF2F7FB);

return Scaffold(
  backgroundColor: bg,
  body: SafeArea(
    child: Column(
      children: [
        const _HeaderWithSearch(),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: _svc.watchOrders().map((list) => list.cast<OrderModel>()), // already sorted desc in service
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty) {
                return const _EmptyLastOrder();
              }

              final last = orders.first;
              final items = last.items;

              if (items.isEmpty) {
                return const _EmptyLastOrder();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72, // tuned to your card proportions
                  ),
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    return _ReorderProductCard(
                      item: it,
                      onAddToCart: () {
                        _svc.addOrIncItem(
                          CartItem(
                            id: it.productId,
                            productId: it.productId,
                            title: it.title,
                            description: '', // not in last order; omit
                            imageUrl: it.imageUrl,
                            price: it.price,
                            qty: 1,
                          ),
                        );
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(const SnackBar(content: Text('Added to cart')));
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  ),
);
}
}

class _HeaderWithSearch extends StatelessWidget {
const _HeaderWithSearch({Key? key}) : super(key: key);

@override
Widget build(BuildContext context) {
const brandBlue = Color(0xFF0E5AA6);

final border = OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
);

return Container(
  color: const Color(0xFFF2F7FB),
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
  child: Column(
    children: [
      // 1) Logo centered at the top
      SizedBox(
        height: 56,
        child: Center(
          child: Image.asset(
            'assets/images/logo_medlink.png',
            height: 32, // adjust 32–40 to taste
            fit: BoxFit.contain,
          ),
        ),
      ),

      const SizedBox(height: 8),

      // 2) Search + blue filter button
      Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: true, // non-functional per scope
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
      ),

      const SizedBox(height: 14),

      // 3) Back chevron left + centered "Last Order" title
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
                tooltip: 'Back',
              ),
            ),
            const Text(
              'Last Order',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            // right spacer keeps the title perfectly centered
            const SizedBox(width: 48),
          ],
        ),
      ),
    ],
  ),
);
}
}
class _ReorderProductCard extends StatelessWidget {
final OrderItem item;
final VoidCallback onAddToCart;
const _ReorderProductCard({
required this.item,
required this.onAddToCart,
Key? key,
}) : super(key: key);

@override
Widget build(BuildContext context) {
const brandBlue = Color(0xFF0E5AA6);
final isAsset = item.imageUrl.startsWith('assets/');
return Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
  ),
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // top image + heart
      Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isAsset
                  ? Image.asset(item.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(item.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_border, color: Colors.redAccent),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Allergy relief', // small subtitle placeholder
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Spacer(),
          Text(
            '${item.price.toStringAsFixed(0)}EG',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: brandBlue,
            ),
          ),
        ],
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onAddToCart,
          child: const Text(
            'Add to cart',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  ),
);
}
}

class _EmptyLastOrder extends StatelessWidget {
const _EmptyLastOrder({Key? key}) : super(key: key);

@override
Widget build(BuildContext context) {
const brandBlue = Color(0xFF0E5AA6);
return Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.receipt_long_rounded, size: 84, color: Colors.grey.shade400),
const SizedBox(height: 16),
const Text(
'No previous orders',
style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
),
const SizedBox(height: 8),
Text(
'Place an order to see it here and reorder fast.',
style: TextStyle(color: Colors.grey.shade600),
),
const SizedBox(height: 16),
OutlinedButton(
onPressed: () => Navigator.of(context).pop(),
style: OutlinedButton.styleFrom(
side: const BorderSide(color: brandBlue),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: const Text('Go back'),
),
],
),
);
}
}