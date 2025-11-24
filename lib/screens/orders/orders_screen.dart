import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/cart_orders_service.dart';
import '../../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State {
  final _svc = CartOrdersService.instance;

  static const bg = Color(0xFFF2F7FB);
  static const brandBlue = Color(0xFF0E5AA6);

  int _currentTab = 1; // Orders selected

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

  void _onNavTap(int i) {
    if (i == _currentTab) return;
    setState(() => _currentTab = i);
    // Replace with your real routes
    switch (i) {
      case 0:
        context.go('/lastOrder');
        break;
      case 1:
        // already here
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/cart');
        break;
    }
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
              child: StreamBuilder<List<OrderModel>>(
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
                            Icon(
                              Icons.inbox_rounded,
                              size: 84,
                              color: Colors.grey.shade400,
                            ),
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
                              style: TextStyle(
                                fontSize: 15,
                                color: grey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1.5,
                                ),
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/home');
                                },
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Browse Products',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
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
                      final firstItem = o.items.isNotEmpty
                          ? o.items.first
                          : null;
                      final img =
                          firstItem?.imageUrl ?? 'assets/images/panadol.png';
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
                            // Improved photo: keeps aspect ratio, shows loader and error fallback
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white,
                                child: AspectRatio(
                                  aspectRatio:
                                      16 /
                                      9, // consistent card shape like the design
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
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Location : ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${o.total.toStringAsFixed(0)}EG',
                                  ),
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

      // Bottom navigation
      bottomNavigationBar: CustomBottomBar(
currentIndex: _currentTab,
onTap: _onNavTap,
// Provide your own assets (selected/unselected)
homeIcon: 'assets/images/home.png',
homeIconSelected: 'assets/images/home_selected.png',
ordersIcon: 'assets/images/order.png',
ordersIconSelected: 'assets/images/order_selected.png',
accountIcon: 'assets/images/user.png',
accountIconSelected: 'assets/images/user_selected.png',
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
                    icon: const Icon(
                      Icons.chevron_left,
                      color: brandBlue,
                      size: 28,
                    ),
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

const brandBlue = Color(0xFF0E5AA6);

class CustomBottomBar extends StatelessWidget {
  final int currentIndex; // 0=Home, 1=Orders, 2=Account
  final ValueChanged<int> onTap;

  // Your icon asset paths (selected/unselected)
  final String homeIcon;
  final String homeIconSelected;
  final String ordersIcon;
  final String ordersIconSelected;
  final String accountIcon;
  final String accountIconSelected;

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.homeIcon,
    required this.homeIconSelected,
    required this.ordersIcon,
    required this.ordersIconSelected,
    required this.accountIcon,
    required this.accountIconSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF2F7FB);
    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BarIcon(
                  asset: currentIndex == 0 ? homeIconSelected : homeIcon,
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _BarIcon(
                  asset: currentIndex == 1 ? ordersIconSelected : ordersIcon,
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _BarIcon(
                  asset: currentIndex == 2 ? accountIconSelected : accountIcon,
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _BarIcon({
    Key? key,
    required this.asset,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your PNG/SVG icon (use flutter_svg for SVGs if needed)
            Image.asset(asset, width: 28, height: 28, fit: BoxFit.contain),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: brandBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _BarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 28),
            const SizedBox(height: 6),
            // small dot indicator only when selected
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image widget with graceful loading, error fallback, and asset/network handling
class _OrderImageContain extends StatelessWidget {
  final String src;
  const _OrderImageContain({required this.src});

  @override
  Widget build(BuildContext context) {
    // Common image builder used for both asset and network
    Widget _build(ImageProvider provider) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(8), // white margin around the pack
          child: Image(
            image: provider,
            fit: BoxFit.contain, // show the entire pack without cropping
            alignment: Alignment.center,
          ),
        ),
      );
    }

    if (src.startsWith('assets/')) {
      return _build(AssetImage(src));
    }

    return Image.network(
      src,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      // Show loader while downloading, with same container
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            _build(const AssetImage('assets/images/transparent.png')),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 36,
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 36,
      ),
    );
  }
}
