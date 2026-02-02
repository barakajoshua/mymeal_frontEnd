import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      // Add to local order history
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
      backgroundColor: const Color(0xFFF5F5F8), // Soft background from design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          "My Cart",
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
               Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.receipt_long, color: Colors.black),
            tooltip: "History",
          ),
        ],
      ),
      body: cartManager.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Your cart is empty",
                    style: TextStyle(color: Colors.grey, fontSize: 18, fontFamily: 'comfortaa'),
                  ),
                ],
              ),
            )
          : Stack(
            children: [
               Positioned.fill(
                 child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 250), // Extra padding for footer
                    itemCount: cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = cartManager.items[index];
                      return _buildCartItemCard(item);
                    },
                  ),
               ),
               Positioned(
                 left: 0,
                 right: 0,
                 bottom: 0,
                 child: _buildCartFooter(),
               ),
            ],
          ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16), // More padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[100],
              backgroundImage: CachedNetworkImageProvider(item.product.imageUrl),
            ),
          ),
          const SizedBox(width: 15),
          // Product Info
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
                const SizedBox(height: 4),
                Text(
                  "Healthy Options", // Placeholder subtitle as per design aesthetics
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'comfortaa',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "RWF ${(item.product.price).toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.black, // Price is black in design
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'comfortaa',
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              GestureDetector(
                onTap: () {
                   cartManager.removeItem(item.product);
                },
                child: const Text(
                  "-",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "${item.quantity}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                   cartManager.addItem(item.product);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF357D5D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    final subtotal = cartManager.totalPrice;
    const deliveryFee = 2000;
    const vat = 0.0; // Assuming 0 for now as not specified logic
    final total = subtotal + deliveryFee + vat;
    final itemCount = cartManager.items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 20),
        
            _buildSummaryRow("Total items", itemCount.toString().padLeft(2, '0')),
            const SizedBox(height: 10),
            _buildSummaryRow("Subtotal", "RWF ${subtotal.toStringAsFixed(0)}", isBold: true),
            const SizedBox(height: 10),
            _buildSummaryRow("VAT", "RWF 0.00"), // Placeholder
            const SizedBox(height: 10),
            _buildSummaryRow("Shipping fee", "RWF ${deliveryFee.toStringAsFixed(0)}", isBold: true),
            
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Payable",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'comfortaa',
                  ),
                ),
                Text(
                  "RWF ${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF357D5D),
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
                    borderRadius: BorderRadius.circular(30), // Rounded pill shape
                  ),
                ),
                child: const Text(
                  "Proceed To Checkout",
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
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'comfortaa',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
            fontFamily: 'comfortaa',
          ),
        ),
      ],
    );
  }
}
