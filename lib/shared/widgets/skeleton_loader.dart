import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake Image Box
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            // Fake Text Lines
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 40, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget: Creates a horizontal list of 3 skeleton cards
// This mimics your "Popular" or "Last Order" lists while loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics:
            const NeverScrollableScrollPhysics(), // Disable scrolling while loading
        itemCount: 3,
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
    );
  }
}
