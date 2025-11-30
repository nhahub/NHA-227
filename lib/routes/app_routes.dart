import 'package:flutter/material.dart';

import '../screens/cart/cart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/last_order_screen.dart';

class AppRoutes {
  static const cart = '/cart';
  static const orders = '/orders';
  static const lastOrder = '/lastOrder';
  static const checkout = '/checkout';

  // MUST be GlobalKey
  static final GlobalKey navigatorKey = GlobalKey();

  // ... routes and onGenerateRoute as you already have ...
  // Static map if you like simple routes
  static Map<String, WidgetBuilder> get routes => {
    '/home': (context) => HomeScreen(),
    cart: (context) => const CartScreen(),
    orders: (context) => OrdersScreen(),
    lastOrder: (context) => LastOrderScreen(),
    checkout: (context) => const CheckoutScreen(),
  };

  // Advanced: onGenerateRoute for custom transitions and passing args
  static Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case cart:
        return _fade(const CartScreen(), settings);
      case orders:
        return _fade(OrdersScreen(), settings);
      case lastOrder:
        return _fade(LastOrderScreen(), settings);
      case checkout:
        return _fade(const CheckoutScreen(), settings);
      default:
        return _fade(
          const _UnknownRouteScreen(),
          const RouteSettings(name: '/unknown'),
        );
    }
  }

  // Transition helper
  static PageRoute _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, anim, secondaryAnim, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Route not found')));
  }
}
