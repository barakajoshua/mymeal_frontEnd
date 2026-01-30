import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:mymeal/models/product.dart';
import 'package:mymeal/data/cart_manager.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int quantity = 1;
  int selectedImageIndex = 0;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF357D5D);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Fixed Header + Image Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Main Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.images[selectedImageIndex],
                          width: double.infinity,
                          height: 350,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
                          ),
                        ),
                      ),
                      // Header Buttons
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                            Row(
                              children: [
                                _buildCircleBtn(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  () => setState(() => isFavorite = !isFavorite),
                                  color: isFavorite ? Colors.red : Colors.black87,
                                ),
                                const SizedBox(width: 15),
                                _buildCircleBtn(Icons.share_outlined, () {
                                  Clipboard.setData(ClipboardData(
                                      text: "Check out this ${widget.product.name} on mymeal!"));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Link copied to clipboard!")),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Thumbnails
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.product.images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => setState(() => selectedImageIndex = index),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selectedImageIndex == index
                                            ? primaryGreen
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(widget.product.images[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Category and Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.product.category,
                              style: const TextStyle(
                                  color: Colors.grey, 
                                  fontSize: 16,
                                  fontFamily: 'comfortaa',
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  "${widget.product.rating}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 16,
                                      fontFamily: 'comfortaa',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 2. Name and Veg Icon
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'comfortaa',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: primaryGreen, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.circle, color: primaryGreen, size: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. Description
                        const Text(
                          "Description",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18,
                              fontFamily: 'comfortaa',
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.grey, 
                                height: 1.5, 
                                fontSize: 14,
                                fontFamily: 'comfortaa',
                            ),
                            children: [
                              TextSpan(text: widget.product.description),
                              const TextSpan(
                                text: " Read more",
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 4. Chef Section
                        if (widget.product.chefName != null) ...[
                          const Text(
                            "Chef",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: Colors.black, // Changed to black for better visibility in the list
                                fontSize: 18,
                                fontFamily: 'comfortaa',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                  image: const DecorationImage(
                                    image: AssetImage("assets/images/chef_hat.png"),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.chefName!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16,
                                          fontFamily: 'comfortaa',
                                      ),
                                    ),
                                    Text(
                                      widget.product.chefSpecialty ?? "Master Chef",
                                      style: const TextStyle(
                                          color: Colors.grey, 
                                          fontSize: 14,
                                          fontFamily: 'comfortaa',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildActionCircle(Icons.chat_bubble_outline),
                              const SizedBox(width: 10),
                              _buildActionCircle(Icons.phone_outlined),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],

                        // 5. Quantity Section
                        const Text(
                          "Quantity",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18,
                              fontFamily: 'comfortaa',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildCounterBtn(Icons.remove, () {
                              if (quantity > 1) setState(() => quantity--);
                            }),
                            Container(
                              width: 60,
                              alignment: Alignment.center,
                              child: Text(
                                "$quantity",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'comfortaa',
                                ),
                              ),
                            ),
                            _buildCounterBtn(Icons.add, () {
                              setState(() => quantity++);
                            }),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // 6. Total Amount Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Amount",
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                                fontFamily: 'comfortaa',
                              ),
                            ),
                            Text(
                              "RWF ${_formatPrice(widget.product.price * quantity)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen, // Use brand green for the price
                                fontFamily: 'comfortaa',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 15, 24, 10), // Reduced bottom padding
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cartManager.addToCart(widget.product, quantity, const []);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${widget.product.name} added to cart!"),
                        backgroundColor: Colors.black,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    const primaryGreen = Color(0xFF357D5D);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryGreen.withOpacity(0.2)),
        ),
        child: Icon(icon, color: primaryGreen, size: 24),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, {Color color = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F0),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFEBD5)),
      ),
      child: Icon(icon, color: const Color(0xFF357D5D), size: 20),
    );
  }
}
