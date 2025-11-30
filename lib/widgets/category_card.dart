import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/category_products', extra: category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: category.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (category.iconPath.startsWith('http')
                ? Image.network(
                    category.iconPath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    category.iconPath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  )),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: category.iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
