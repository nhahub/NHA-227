import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/repositories/product_repository.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/shared/widgets/skeleton_loader.dart';
import 'package:medilink_app/widgets/category_card.dart';
import 'package:medilink_app/widgets/pharmacy_card.dart';
import 'package:medilink_app/widgets/product_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch loading state for skeleton effect
    final isLoading = context.watch<ProductRepository>().isLoading;
    final products = context.watch<ProductRepository>().products;
    final categories = context.watch<ProductRepository>().categories;
    final pharmacies = context.watch<ProductRepository>().pharmacies;
    final popularProducts = context.watch<ProductRepository>().popularProducts;

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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: const AssetImage('assets/images/user_avatar.png'),
                    child: const Icon(Icons.person, color: Colors.transparent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hussien', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Row(
                          children: const [
                            Text('sidi bashr', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ],
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
            
            const CustomSearchBar(),
            
            // --- Sections ---

            // Last Order
            _buildSectionHeader(AppStrings.lastOrder, onMorePressed: () => context.push('/lastOrder')),
            isLoading 
              ? const SkeletonList() 
              : _buildProductList(products.take(3).toList()),
            
            // Categories
            _buildSectionHeader(AppStrings.categories, onMorePressed: () => context.push('/home/categories')),
            _buildCategoriesGrid(categories.take(3).toList()),
            
            // Pharmacies
            _buildSectionHeader(AppStrings.pharmacies, onMorePressed: () => context.push('/home/pharmacies')),
            _buildPharmaciesList(pharmacies),
            
            // Popular
            _buildSectionHeader(AppStrings.popular, onMorePressed: () => context.push('/home/popular')),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: onMorePressed,
            child: Row(
              children: const [
                Text(AppStrings.more, style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List products) {
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
          crossAxisCount: 3, childAspectRatio: 1, crossAxisSpacing: 12, mainAxisSpacing: 12,
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