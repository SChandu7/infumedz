import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Cart"));
}

class CartBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final ValueChanged<List<Map<String, dynamic>>>? onCartUpdated;

  const CartBottomSheet({
    super.key,
    required this.initialItems,
    this.onCartUpdated,
  });

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  late List<Map<String, dynamic>> _cartItems;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.initialItems);
  }

  double get total {
    return _cartItems.fold(0.0, (sum, item) {
      final raw = item["price"];
      if (raw == null) return sum;

      final cleaned = raw.toString().replaceAll("₹", "").replaceAll(",", "");

      return sum + (double.tryParse(cleaned) ?? 0);
    });
  }

  void _removeItem(int index) {
    if (_processing) return;
    _processing = true;

    final removedItem = _cartItems[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _CartItemTile(item: removedItem),
      ),
      duration: const Duration(milliseconds: 280),
    );

    setState(() {
      _cartItems.removeAt(index);
    });

    widget.onCartUpdated?.call(List.from(_cartItems));

    Future.delayed(const Duration(milliseconds: 300), () {
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Your Cart",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// 🔹 CART LIST
            Expanded(
              child: _cartItems.isEmpty
                  ? const _EmptyCartView()
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: _cartItems.length,
                      padding: const EdgeInsets.all(14),
                      itemBuilder: (context, index, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: _CartItemTile(
                            item: _cartItems[index],
                            onDelete: () => _removeItem(index),
                          ),
                        );
                      },
                    ),
            ),

            /// 🔹 BILLING
            _BillingSection(total: total),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDelete;

  const _CartItemTile({required this.item, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item["image"] as String,
              width: 60,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["price"] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _BillingSection extends StatelessWidget {
  final double total;

  const _BillingSection({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  "₹${total.toStringAsFixed(0)}",
                  key: ValueKey(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: () {
              // backend checkout later
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5FD8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Proceed to Checkout",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class WishlistBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final Function(Map<String, dynamic>) onAddToCart;
  final ValueChanged<List<Map<String, dynamic>>>? onWishlistUpdated;

  const WishlistBottomSheet({
    super.key,
    required this.initialItems,
    required this.onAddToCart,
    this.onWishlistUpdated,
  });

  @override
  State<WishlistBottomSheet> createState() => _WishlistBottomSheetState();
}

class _WishlistBottomSheetState extends State<WishlistBottomSheet> {
  late List<Map<String, dynamic>> _wishlistItems;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool _processing = false; // prevents double taps

  @override
  void initState() {
    super.initState();
    _wishlistItems = List.from(widget.initialItems);
  }

  void _removeFromWishlist(int index) {
    final removedItem = _wishlistItems[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _WishlistItemTile(item: removedItem),
      ),
      duration: const Duration(milliseconds: 280),
    );

    setState(() {
      _wishlistItems.removeAt(index);
    });

    widget.onWishlistUpdated?.call(List.from(_wishlistItems));
  }

  void _moveToCart(int index) async {
    if (_processing) return;
    _processing = true;

    final item = _wishlistItems[index];

    widget.onAddToCart(item);
    _removeFromWishlist(index);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Moved to cart"),
        backgroundColor: Color(0xFF0E5FD8),
        duration: Duration(milliseconds: 900),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Wishlist",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// 🔹 LIST
            Expanded(
              child: _wishlistItems.isEmpty
                  ? const _EmptyWishlistView()
                  : AnimatedList(
                      key: _listKey,
                      padding: const EdgeInsets.all(14),
                      initialItemCount: _wishlistItems.length,
                      itemBuilder: (context, index, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: _WishlistItemTile(
                            item: _wishlistItems[index],
                            onAddToCart: () => _moveToCart(index),
                            onRemove: () => _removeFromWishlist(index),
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

class _WishlistItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;

  const _WishlistItemTile({
    required this.item,
    this.onAddToCart,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              item["image"] as String,
              width: 64,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          /// ACTIONS
          Column(
            children: [
              InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5FD8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 18,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onRemove,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWishlistView extends StatelessWidget {
  const _EmptyWishlistView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            "Your wishlist is empty",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
