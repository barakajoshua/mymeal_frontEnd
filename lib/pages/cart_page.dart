import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mymeal/data/cart_manager.dart';
import 'package:mymeal/data/order_manager.dart';
import 'package:mymeal/pages/history_page.dart';
import 'package:mymeal/widgets/order_success_dialog.dart';

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

  void _placeOrder() {
    if (cartManager.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    orderManager.placeOrder(cartManager.items, cartManager.totalPrice);
    cartManager.clearCart();

    showDialog(
      context: context,
      builder: (context) => const OrderSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.history, color: Colors.black),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        color: const Color(0xFF32B768),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Delivery Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF32B768),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF32B768).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Delivery to Home",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'comfortaa',
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "Utama Street no. 14, Rumbal",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'comfortaa',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "2.4 km",
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                         // Arc decoration (simplified)
                        Container(
                          width: 50,
                          height: 50,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.white.withOpacity(0.1), width: 8),
                         ),
                         child: const Icon(Icons.chevron_right, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Header and Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Order (${cartManager.totalCount})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'comfortaa',
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'comfortaa',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Cart Items List
                  if (cartManager.items.isEmpty)
                     const Padding(
                       padding: EdgeInsets.only(top: 50),
                       child: Center(child: Text("Cart is empty", style: TextStyle(color: Colors.grey))),
                     )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartManager.items.length,
                      itemBuilder: (context, index) {
                        final item = cartManager.items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.restaurant, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'comfortaa',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Quantity Control (Visual only for now as CartManager might not have update methods yet, 
                                        // but UI should look like the design. 
                                        // Assuming CartManager handles simple add/clear for this task scope, but design shows +/-
                                        // Since user didn't ask for full +/- logic update in manager, I'll keep it simple or visual.)
                                        // Actually, let's just show the quantity.
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.remove, size: 16, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "${item.quantity}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                               padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF32B768),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "RWF ${(item.product.price * item.quantity).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Color(0xFF32B768),
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
                      },
                    ),
                ],
              ),
            ),
          ),
          // Total and Button Area
           Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32B768),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF32B768).withOpacity(0.4),
                ),
                child: const Text(
                  "Place Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'comfortaa',
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
