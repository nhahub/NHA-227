import 'package:flutter/material.dart';
import '../services/cart_orders_service.dart';
import '../models/order.dart'; // contains OrderModel and OrderItem

class OrdersScreen extends StatelessWidget {
OrdersScreen({Key? key}) : super(key: key);

final _svc = CartOrdersService.instance;

Color _statusColor(String s) {
switch (s.toLowerCase()) {
case 'delivered':
return const Color(0xFF16A34A); // green
case 'canceled':
return const Color(0xFFDC2626); // red
default:
return const Color(0xFFF59E0B); // amber (In Process)
}
}

String _dateLabel(DateTime? dt) {
if (dt == null) return '';
final d = dt.toLocal();
return '${d.year}-${d.month}-${d.day}';
}

@override
Widget build(BuildContext context) {
const bg = Color(0xFFF2F7FB);
const brandBlue = Color(0xFF0E5AA6);
final grey = Colors.grey.shade600;
return Scaffold(
  backgroundColor: bg,
  body: SafeArea(
    child: Column(
      children: [
        const _OrdersHeader(),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: _svc.watchOrders().map((list) => list.cast<OrderModel>()), // users/{uid}/orders stream
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty) {
 return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0), // side breathing room
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // More top space so it doesn’t feel cramped
        const SizedBox(height: 12),

        Icon(Icons.inbox_rounded, size: 84, color: Colors.grey.shade400),

        // Icon -> title
        const SizedBox(height: 20),

        const Text(
          'No orders yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.2,
          ),
        ),

        // Title -> subtitle
        const SizedBox(height: 10),

        Text(
          'Start shopping to place your first order.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: grey, height: 1.4),
        ),

        // Subtitle -> button
        const SizedBox(height: 22),

        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1.5,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // or push to your Home route
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: const Text(
              'Browse Products',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),

        // Bottom breathing room
        const SizedBox(height: 24),
      ],
    ),
  ),
);
}

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final o = orders[i];
                  final firstItem = o.items.isNotEmpty ? o.items.first : null;
                  final img = firstItem?.imageUrl ?? 'assets/images/panadol.png';
                  final title = firstItem?.title ?? 'Order';
                  const locationText = 'Sidi Basher, Alexandria'; // placeholder until address is added

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: img.startsWith('assets/')
                              ? Image.asset(
                                  img,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  img,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dateLabel(o.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Location : ',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(text: locationText),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Price : ',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(text: '${o.total.toStringAsFixed(0)}EG'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          o.status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _statusColor(o.status),
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
      ],
    ),
  ),
);
}
}

class _OrdersHeader extends StatelessWidget {
const _OrdersHeader({Key? key}) : super(key: key);

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
Align(
alignment: Alignment.centerLeft,
child: IconButton(
icon: const Icon(Icons.chevron_left,
color: brandBlue, size: 28),
onPressed: () => Navigator.of(context).maybePop(),
),
),
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
'My Orders',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w800,
color: Colors.black87,
),
),
const SizedBox(height: 12),
],
),
);
}
}