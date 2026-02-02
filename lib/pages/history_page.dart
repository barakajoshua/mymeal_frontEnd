import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getMyOrders();
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _orders = result['data'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchOrders();
  }

  List<dynamic> _filterOrders(List<String> statuses) {
    return _orders.where((order) {
      final status = (order['status'] ?? "PENDING").toString().toUpperCase();
      return statuses.contains(status);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
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
          bottom: const TabBar(
            labelColor: Color(0xFF357D5D),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF357D5D),
            labelStyle: TextStyle(
              fontFamily: 'comfortaa',
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF357D5D)))
            : TabBarView(
                children: [
                  _buildOrderList(["PENDING", "CONFIRMED", "PROCESSING", "ON_THE_WAY"]),
                  _buildOrderList(["COMPLETED", "DELIVERED"]),
                  _buildOrderList(["CANCELLED", "REJECTED"]),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderList(List<String> statuses) {
    final filteredOrders = _filterOrders(statuses);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
             const SizedBox(height: 15),
             const Text("No orders found", style: TextStyle(color: Colors.grey, fontFamily: 'comfortaa')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF357D5D),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: filteredOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final List<dynamic> items = order['items'] ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final totalPrice = order['total_amount'] ?? 0;
    
    // Fallback if no item details
    final productName = firstItem != null ? (firstItem['product_name'] ?? 'Order #${order['id']}') : 'Order #${order['id']}';
    
    // Looking at CartPage, item.product.imageUrl exists.
    final String? imageUrl = firstItem != null ? firstItem['image_url'] : null;

    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Image
               Container(
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.1),
                       blurRadius: 5,
                       offset: const Offset(0, 2),
                     ),
                   ],
                 ),
                 child: CircleAvatar(
                   radius: 30,
                   backgroundColor: Colors.grey[100],
                   backgroundImage: imageUrl != null 
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                   child: imageUrl == null 
                      ? const Icon(Icons.fastfood, color: Colors.grey)
                      : null,
                 ),
               ),
               const SizedBox(width: 15),
               // Info
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Text(
                             productName,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                               fontFamily: 'comfortaa',
                             ),
                           ),
                         ),
                         Text(
                           "#${order['id']}",
                           style: TextStyle(
                             color: Colors.grey[400],
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 5),
                     Text(
                       items.length > 1 ? "$productName and ${items.length - 1} others" : "1 Item",
                       style: TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: 'comfortaa'),
                     ),
                     const SizedBox(height: 8),
                     Row(
                       children: [
                         Text(
                           "RWF $totalPrice",
                           style: const TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                             fontFamily: 'comfortaa',
                            ),
                         ),
                         const SizedBox(width: 10),
                         Container(
                           width: 1, 
                           height: 12, 
                           color: Colors.grey[300]
                         ),
                         const SizedBox(width: 10),
                          Text(
                           "Today", // Date formatting can be added here
                           style: TextStyle(
                             color: Colors.grey[400],
                             fontSize: 12,
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
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Cancel logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F5F2), // Very light green/grey
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color(0xFF357D5D), // Dark text for contrast
                      fontWeight: FontWeight.bold,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                     // Track Order Logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF357D5D),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Track Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
