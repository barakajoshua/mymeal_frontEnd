import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mymeal/data/cart_manager.dart';
import 'package:mymeal/data/order_manager.dart';
import 'package:mymeal/pages/history_page.dart';
import 'package:mymeal/widgets/order_success_dialog.dart';
import 'package:mymeal/services/api_client.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    cartManager.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _placeOrder() async {
    if (cartManager.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF357D5D)),
      ),
    );

    // Format items for backend
    final items = cartManager.items.map((item) {
      return {
        "productId": int.tryParse(item.product.id) ?? 0,
        "quantity": item.quantity
      };
    }).toList();

    // Default delivery location
    final deliveryLocation = {
      "latitude": -1.9441,
      "longitude": 30.0619,
      "address": "Kigali Heights"
    };

    final result = await ApiClient.createOrder(
      items: items,
      deliveryLocation: deliveryLocation,
      notes: "Placed from Mobile App",
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (result['success']) {
      // Add to local order history for UI consistency (optional but good for history page)
      orderManager.placeOrder(cartManager.items, cartManager.totalPrice);
      
      cartManager.clearCart();
      showDialog(
        context: context,
        builder: (context) => const OrderSuccessDialog(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background like design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Order",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'comfortaa',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              cartManager.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cart cleared")),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.black),
          ),
        ],
      ),
      body: cartManager.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Your cart is empty",
                    style: TextStyle(color: Colors.grey, fontSize: 18, fontFamily: 'comfortaa'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = cartManager.items[index];
                      return _buildCartItemCard(item);
                    },
                  ),
                ),
                _buildCartFooter(),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[50],
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'comfortaa',
                        ),
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                // Pill quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // CartManager would need a decreaseQuantity method for full functionality
                              // Keeping it visual as per design request scope
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("-", style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "${item.quantity}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // CartManager would need an increaseQuantity method
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("+", style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "RWF ${(item.product.price * item.quantity).toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFF357D5D),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'comfortaa',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    final subtotal = cartManager.totalPrice;
    const deliveryFee = 2000;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dash separator
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: Colors.grey[200],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'comfortaa'),
              ),
              Text(
                "RWF ${total.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'comfortaa',
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF357D5D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Proceed to Checkout",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'comfortaa',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
