import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/cart_orders_service.dart';
import '../../repositories/auth_repository.dart';
import '../../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _svc = CartOrdersService.instance;

  static const bg = Color(0xFFF2F7FB);
  static const brandBlue = Color(0xFF0E5AA6);

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
    final grey = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const _OrdersHeader(),
            Expanded(
              child: Builder(builder: (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Icon(Icons.lock_outline, size: 84, color: Colors.grey.shade400),
                          const SizedBox(height: 20),
                          const Text(
                            'Sign in to see your orders',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your orders are saved to your account and visible after signing in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: grey, height: 1.4),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 1.5,
                              ),
                              onPressed: () {
                                final authRepo = Provider.of<AuthRepository>(ctx, listen: false);
                                authRepo.openSignInScreen(ctx);
                              },
                              icon: const Icon(Icons.login, size: 20),
                              label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<OrderModel>>(
                  stream: _svc.watchOrders().map((e) => e.cast<OrderModel>()),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Icon(Icons.inbox_rounded, size: 84, color: Colors.grey.shade400),
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
                              const SizedBox(height: 10),
                              Text(
                                'Start shopping to place your first order.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, color: grey, height: 1.4),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 1.5,
                                  ),
                                  onPressed: () {
                                    // CHANGE: Go to Home instead of pushing a new route
                                    context.go('/home');
                                  },
                                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                                  label: const Text(
                                    'Browse Products',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                              ),
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
                        const locationText = 'Sidi Basher, Alexandria';

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
                                child: Container(
                                  color: Colors.white,
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _OrderImageContain(src: img),
                                  ),
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
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 16, height: 1.5),
                                  children: const [
                                    TextSpan(text: 'Location : ', style: TextStyle(fontWeight: FontWeight.w800)),
                                    TextSpan(text: locationText),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 16, height: 1.5),
                                  children: [
                                    const TextSpan(text: 'Price : ', style: TextStyle(fontWeight: FontWeight.w800)),
                                    TextSpan(text: '${o.total.toStringAsFixed(0)} EG'),
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
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

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
                    icon: const Icon(Icons.chevron_left, color: brandBlue, size: 28),
                    // CHANGE: Smart back button logic
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        // Fallback to home if opened directly (e.g. from bottom nav)
                        context.go('/home');
                      }
                    },
                  ),
                ),
                Image.asset('assets/images/logo_medlink.png', height: 40, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'My Orders',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _OrderImageContain extends StatelessWidget {
  final String src;
  const _OrderImageContain({required this.src});

  @override
  Widget build(BuildContext context) {
    Widget buildImage(ImageProvider provider) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image(
            image: provider,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      );
    }

    if (src.startsWith('assets/')) {
      return buildImage(AssetImage(src));
    }

    return Image.network(
      src,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            buildImage(const AssetImage('assets/images/transparent.png')), // Transparent placeholder if exists
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
        );
      },
    );
  }
}