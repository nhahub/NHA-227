import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/cart_orders_service.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';

class LastOrderScreen extends StatefulWidget {
  const LastOrderScreen({super.key});

  @override
  State<LastOrderScreen> createState() => _LastOrderScreenState();
}

enum _Filter { all, priceAsc, priceDesc }

class _LastOrderScreenState extends State<LastOrderScreen> {
  final _svc = CartOrdersService.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _dedupeByProduct(List items) {
    // Keep the last occurrence for each productId
    final map = <String, OrderItem>{};
    for (final it in items) {
      map[it.productId] = it;
    }
    return map.values.toList();
  }

  List _applySearchAndFilter(List items) {
    var list = items;

    // Search by title
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }

    // Filter/sort
    switch (_filter) {
      case _Filter.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _Filter.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _Filter.all:
        // no-op
        break;
    }
    return list;
  }

  Future _openFilterSheet() async {
    final choice = await showModalBottomSheet<_Filter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: const Icon(Icons.filter_alt_off_outlined),
                title: const Text('All'),
                onTap: () => Navigator.pop(context, _Filter.all),
                selected: _filter == _Filter.all,
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Price: Low to High'),
                onTap: () => Navigator.pop(context, _Filter.priceAsc),
                selected: _filter == _Filter.priceAsc,
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Price: High to Low'),
                onTap: () => Navigator.pop(context, _Filter.priceDesc),
                selected: _filter == _Filter.priceDesc,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
    if (choice != null && mounted) {
      setState(() => _filter = choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F7FB);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderWithSearch(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              onFilterTap: _openFilterSheet,
            ),
            Expanded(
              child: StreamBuilder<List>(
                stream: _svc.watchOrders().map((e) => e.cast()),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final orders = snap.data ?? [];
                  if (orders.isEmpty) return const _EmptyLastOrder();

                  // Collect ALL items from ALL orders (recommendations from history)
                  final allItems = orders.expand((o) => o.items).toList();
                  if (allItems.isEmpty) return const _EmptyLastOrder();

                  // Deduplicate and then apply search + filter
                  final unique = _dedupeByProduct(allItems);
                  final items = _applySearchAndFilter(unique);

                  if (items.isEmpty) {
                    return const _EmptyLastOrder();
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        // give cards more vertical room (tweak 0.65..0.72 if needed)
                        childAspectRatio: 0.65,
                      ),

                      itemBuilder: (ctx, i) {
                        final it = items[i];
                        return _ReorderProductCard(
                          item: it,
                          onAddToCart: () async {
                            await _svc.addOrIncItem(
                              CartItem(
                                id: it.productId,
                                productId: it.productId,
                                title: it.title,
                                description: '',
                                imageUrl: it.imageUrl,
                                price: it.price,
                                qty: 1,
                              ),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF16A34A),
                                content: Text('Added to cart'),
                              ),
                            );
                          },
                        );
                      },
                    ),
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

class _HeaderWithSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  const _HeaderWithSearch({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0E5AA6);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

    return Container(
      color: const Color(0xFFF2F7FB),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          // Logo
          SizedBox(
            height: 56,
            child: Center(
              child: Image.asset(
                'assets/images/logo_medlink.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Search (icon on RIGHT) + filter (asset)
          Row(
            children: [
              // Taller search field with suffix asset icon
              Expanded(
                child: SizedBox(
                  height: 56, // increased height
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      // Put icon on the RIGHT
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/search.png', // your asset
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18, // makes the field taller
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter button using asset icon
              InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48, // taller like the design
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 32, 86, 147),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/fav.png', // your asset
                    width: 33,
                    height: 33,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Back + centered title
          SizedBox(
            height: 44,
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
                    // CORRECTED BACK LOGIC
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        // If no history, go to a safe place like Orders tab or Home
                        context.go('/home');
                      }
                    },
                    tooltip: 'Back',
                  ),
                ),
                const Text(
                  'Last Order',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavToggleAsset extends StatefulWidget {
  final String offAsset; // e.g. assets/icons/heart_off.png
  final String onAsset; // e.g. assets/icons/heart_on.png
  final double size; // visual icon size inside the pill
  final EdgeInsets padding; // inner padding for the pill
  final VoidCallback? onToggle; // called after state changes
  final bool? value; // optional external control
  final ValueChanged<bool>? onChanged;

  const FavToggleAsset({
    super.key,
    required this.offAsset,
    required this.onAsset,
    this.size = 18,
    this.padding = const EdgeInsets.all(8),
    this.onToggle,
    this.value,
    this.onChanged,
  });

  @override
  State<FavToggleAsset> createState() => _FavToggleAssetState();
}

class _FavToggleAssetState extends State<FavToggleAsset> {
  bool _internal = false;
  bool get _selected => widget.value ?? _internal;

  void _handleTap() {
    final next = !_selected;
    if (widget.value == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _selected ? widget.onAsset : widget.offAsset;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding,
          child: Image.asset(
            iconPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ReorderProductCard extends StatefulWidget {
  final OrderItem item;
  final VoidCallback onAddToCart;
  const _ReorderProductCard({required this.item, required this.onAddToCart});

  @override
  State<_ReorderProductCard> createState() => _ReorderProductCardState();
}

class _ReorderProductCardState extends State<_ReorderProductCard> {
  static const brandBlue = Color(0xFF0E5AA6);
  final bool _fav =
      false; // local toggle; persist in Firestore if you add wishlists

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final isAsset = it.imageUrl.startsWith('assets/');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // slightly smaller padding to save vertical pixels
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top image area (fixed height but smaller than before)
          SizedBox(
            height: 100, // reduced from 110/140 to avoid overflow
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    // remove inner padding here to avoid adding extra height
                    color: Colors.white,
                    child: isAsset
                        ? Image.asset(
                            it.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          )
                        : Image.network(
                            it.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 100,
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),

                // small heart toggle at top-right
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavToggleAsset(
                    offAsset: 'assets/images/heart_off.png',
                    onAsset: 'assets/images/heart_on.png',
                    size: 18,
                    padding: const EdgeInsets.all(6),
                    onChanged: (isFav) {},
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Title + price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${it.price.toStringAsFixed(0)}EG',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: brandBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Allergy relief',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 10),

          // CTA button - full width, comfortable touch size
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: widget.onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              child: const Text('Add to cart'),
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
    const brandBlue = Color(0xFF0E5AA6);
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Place an order to see recommendations here.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: brandBlue),
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
