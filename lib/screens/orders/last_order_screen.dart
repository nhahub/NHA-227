import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/repositories/product_repository.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/widgets/product_card.dart';
import 'package:provider/provider.dart'; // ← ADD THIS
import '../../services/cart_orders_service.dart';
import '../../models/order.dart';

class LastOrderScreen extends StatefulWidget {
  const LastOrderScreen({super.key});

  @override
  State<LastOrderScreen> createState() => _LastOrderScreenState();
}

class _LastOrderScreenState extends State<LastOrderScreen> {
  final _svc = CartOrdersService.instance;

  List<OrderItem> _dedupeByProduct(List<OrderItem> items) {
    // Keep the last occurrence for each productId
    final map = <String, OrderItem>{};
    for (final it in items) {
      map[it.productId] = it;
    }
    return map.values.toList();
  }

  // ✅ UPDATED: Now accepts ProductRepository to check favorites
  List<Product> _convertToProducts(
    List<OrderItem> orderItems,
    ProductRepository productRepo,
  ) {
    return orderItems.map((orderItem) {
      // ✅ Check if this product is in favorites
      final isFavorite = productRepo.isFavoriteById(orderItem.productId);
      
      return Product(
        id: orderItem.productId,
        name: orderItem.title,
        description: 'Allergy relief',
        shortDescription: '',
        price: orderItem.price,
        currency: 'EGP',
        imageUrl: orderItem.imageUrl,
        category: 'Medicine',
        rating: 0.0,
        reviewCount: 0,
        isFavorite: isFavorite, // ✅ Now uses actual favorite state
        isPopular: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get ProductRepository to access favorite functionality
    final productRepo = context.watch<ProductRepository>();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Last Order',
        showBackButton: true,
      ),
      body: Column(
        children: [
          const CustomSearchBar(),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _svc.watchOrders().map((orders) => orders.cast<OrderModel>()),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                
                final List<OrderModel> orders = snap.data ?? [];
                if (orders.isEmpty) return const _EmptyLastOrder();

                // Collect ALL items from ALL orders
                final List<OrderItem> allItems = [];
                for (final order in orders) {
                  allItems.addAll(order.items);
                }
                    
                if (allItems.isEmpty) return const _EmptyLastOrder();

                // Deduplicate
                final List<OrderItem> unique = _dedupeByProduct(allItems);
                
                // Convert to Products with favorite state
                final List<Product> products = _convertToProducts(
                  unique,
                  productRepo, // ✅ Pass ProductRepository
                );

                if (products.isEmpty) {
                  return const Center(
                    child: Text('No items found'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]); // ✅ Now has correct isFavorite
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLastOrder extends StatelessWidget {
  const _EmptyLastOrder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 84,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No previous orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Place an order to see recommendations here.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0E5AA6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}