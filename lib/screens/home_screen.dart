import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/repositories/product_repository.dart';
import 'package:medilink_app/services/cart_orders_service.dart'; // ADD THIS
import 'package:medilink_app/services/user_sevice.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/skeleton_loader.dart';
import 'package:medilink_app/widgets/category_card.dart';
import 'package:medilink_app/widgets/pharmacy_card.dart';
import 'package:medilink_app/widgets/product_card.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart'; // ADD THIS

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Loading...';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await UserService.instance.getUserName();
      if (mounted) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
        });
      }
    }
  }

  // Convert OrderItems to Products
  List<Product> _convertOrderItemsToProducts(List<OrderItem> orderItems, ProductRepository productRepo) {
    return orderItems.map((orderItem) {
      final isFavorite = productRepo.isFavoriteById(orderItem.productId);
      
      return Product(
        id: orderItem.productId,
        name: orderItem.title,
        description: 'From your previous order',
        shortDescription: '',
        price: orderItem.price,
        currency: 'EGP',
        imageUrl: orderItem.imageUrl,
        category: 'Medicine',
        rating: 0.0,
        reviewCount: 0,
        isFavorite: isFavorite,
        isPopular: false,
      );
    }).toList();
  }

  // Deduplicate order items by productId
  List<OrderItem> _dedupeByProduct(List<OrderItem> items) {
    final map = <String, OrderItem>{};
    for (final it in items) {
      map[it.productId] = it;
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductRepository>().isLoading;
    final productRepo = context.watch<ProductRepository>();
    final categories = productRepo.categories;
    final pharmacies = productRepo.pharmacies;
    final popularProducts = productRepo.popularProducts;

    return Scaffold(
      appBar: CustomAppBar(title: AppStrings.appName),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('/profile');
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _userName.isNotEmpty && 
                        _userName != 'Loading...' && 
                        _userName != 'User' && 
                        _userName != 'Guest'
                            ? _userName[0].toUpperCase() 
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.push('/profile');
                      },
                      child: Text(
                        _userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    color: AppColors.primary,
                    iconSize: 26,
                    onPressed: () => context.push('/home/favorites'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    color: AppColors.primary,
                    iconSize: 26,
                    onPressed: () => context.go('/cart'),
                  ),
                ],
              ),
            ),
            
            // Full Width Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  print('🔍 Searching for: $value');
                },
              ),
            ),
            
            // ✅ Last Order - Show only if orders exist
            StreamBuilder<List<OrderModel>>(
              stream: CartOrdersService.instance.watchOrders().map((orders) => orders.cast<OrderModel>()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Don't show anything while loading
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink(); // Don't show on error
                }

                final orders = snapshot.data ?? [];
                
                // ✅ Don't show section if no orders
                if (orders.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Collect all items from all orders
                final List<OrderItem> allItems = [];
                for (final order in orders) {
                  allItems.addAll(order.items);
                }

                // ✅ Don't show if no items
                if (allItems.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Deduplicate items
                final uniqueItems = _dedupeByProduct(allItems);
                
                // Convert to Products
                final orderProducts = _convertOrderItemsToProducts(
                  uniqueItems,
                  productRepo,
                );

                // ✅ Only show up to 3 items from orders
                final displayProducts = orderProducts.take(3).toList();

                // ✅ Show the Last Order section with actual order items
                return Column(
                  children: [
                    _buildSectionHeader(
                      AppStrings.lastOrder,
                      onMorePressed: () => context.push('/lastOrder'),
                    ),
                    _buildProductList(displayProducts),
                  ],
                );
              },
            ),
            
            // Categories
            _buildSectionHeader(
              AppStrings.categories,
              onMorePressed: () => context.push('/home/categories'),
            ),
            _buildCategoriesGrid(categories.take(3).toList()),
            
            // Pharmacies
            _buildSectionHeader(
              AppStrings.pharmacies,
              onMorePressed: () => context.push('/home/pharmacies'),
            ),
            _buildPharmaciesList(pharmacies),
            
            // Popular
            _buildSectionHeader(
              AppStrings.popular,
              onMorePressed: () => context.push('/home/popular'),
            ),
            isLoading 
              ? const SkeletonList() 
              : _buildProductList(popularProducts),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onMorePressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onMorePressed,
            child: Row(
              children: const [
                Text(
                  AppStrings.more,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 280,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }

  Widget _buildCategoriesGrid(List categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) => CategoryCard(category: categories[index]),
      ),
    );
  }

  Widget _buildPharmaciesList(List pharmacies) {
    return SizedBox(
      height: 290,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pharmacies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => PharmacyCard(pharmacy: pharmacies[index]),
      ),
    );
  }
}