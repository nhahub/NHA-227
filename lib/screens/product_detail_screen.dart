import 'package:flutter/material.dart';
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/widgets/related_products.dart';
import 'package:medilink_app/widgets/active_ingredient.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../services/cart_orders_service.dart';
import '../repositories/auth_repository.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Product Image & Tags ---
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[50],
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(product.imageUrl, fit: BoxFit.contain)
                          : Image.asset(product.imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  // Stock Badge
                  if (product.stock < 10)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Only ${product.stock} left',
                          style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Name, Price, Rating ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${product.price.toInt()} ${product.currency}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rating Row
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        ' (${product.reviewCount} reviews)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Spacer(),
                      if (product.stock > 0)
                        const Text("In Stock", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                      else
                        const Text("Out of Stock", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Short Description
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. DYNAMIC ATTRIBUTES (Dosage, Active Ingredient, etc.) ---
                  if (product.attributes.isNotEmpty) ...[
                    const Text(
                      "Specifications",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: product.attributes.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  // Capitalize first letter of key (e.g. "dosage" -> "Dosage")
                                  "${entry.key[0].toUpperCase()}${entry.key.substring(1)}", 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                Flexible(
                                  child: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 4. Overview ---
                  if (product.overview.isNotEmpty) ...[
                    const Text(AppStrings.overview, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      product.overview,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 5. How to Use ---
                  if (product.howToUse.isNotEmpty) ...[
                    const Text(AppStrings.howToUse, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.howToUse,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),

            // --- 6. Related Products ---
            RelatedProductsWidget(currentProduct: product),
            const SizedBox(height: 24),

            // --- 7. Active Ingredient ---
            ActiveIngredientWidget(currentProduct: product),
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // Bottom Bar with Price and Add to Cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () async {
              // Add to Cart Logic: ensure signed in, then add item to cart
              final auth = context.read<AuthRepository>();
              try {
                final uid = await auth.ensureSignedIn(context);
                if (uid == null) {
                  // user didn't sign in / timed out — try anonymous sign-in for quick dev testing
                  try {
                    final res = await FirebaseAuth.instance.signInAnonymously();
                    if (res.user == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please sign in to add items to cart')),
                      );
                      return;
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please sign in to add items to cart')),
                    );
                    return;
                  }
                }

                // Build CartItem from product
                final item = CartItem(
                  id: product.id,
                  productId: product.id,
                  title: product.name,
                  description: product.shortDescription.isNotEmpty ? product.shortDescription : product.description,
                  imageUrl: product.imageUrl,
                  price: product.price,
                  qty: 1,
                );

                await CartOrdersService.instance.addOrIncItem(item);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not add to cart: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Add to Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}