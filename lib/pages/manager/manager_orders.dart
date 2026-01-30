import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:intl/intl.dart';

class ManagerOrders extends StatefulWidget {
  const ManagerOrders({super.key});

  @override
  State<ManagerOrders> createState() => _ManagerOrdersState();
}

class _ManagerOrdersState extends State<ManagerOrders> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allOrders = [];
  bool _isLoading = true;

  // Tabs match backend status values
  // Backend statuses: PENDING, CONFIRMED, PREPARING, OUT_FOR_DELIVERY, DELIVERED, COMPLETED, REJECTED, CANCELLED
  final List<String> _tabs = [
    "PENDING",
    "CONFIRMED",
    "PREPARING",
    "OUT_FOR_DELIVERY",
    "DELIVERED",
    "CANCELLED"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllOrders();
    
    print("DEBUG: Load orders result: ${result['success']}");
    
    if (result['success']) {
      final orders = result['data'] ?? [];
      print("DEBUG: Loaded ${orders.length} orders");
      
      // Debug: Print status of each order
      for (var order in orders) {
        print("DEBUG: Order ${order['id']} has status: ${order['status']}");
      }
      
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to load orders")),
        );
      }
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    print("DEBUG: Updating order $orderId to status: $newStatus");
    final result = await ApiClient.updateOrderStatus(orderId, newStatus);
    print("DEBUG: Update result: ${result['success']}");
    
    if (result['success']) {
      // Refresh the orders list first
      await _loadOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order updated to ${newStatus.replaceAll('_', ' ')}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Failed to update status"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF357D5D),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF357D5D),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'comfortaa'),
          tabs: _tabs.map((tab) {
            // Display "On the Way" for OUT_FOR_DELIVERY
            String displayText = tab == "OUT_FOR_DELIVERY" ? "On the Way" : tab.replaceAll('_', ' ');
            return Tab(text: displayText);
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((status) => _buildOrderList(status)).toList(),
            ),
    );
  }

  Widget _buildOrderList(String status) {
    // Filter orders locally for now as getAllOrders returns everything
    final filteredOrders = _allOrders.where((order) {
      return (order['status'] ?? '').toString().toUpperCase() == status;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          "No $status orders",
          style: const TextStyle(color: Colors.grey, fontFamily: 'comfortaa'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildOrderItem(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    // order items, total, customer info
    final items = order['items'] as List<dynamic>? ?? [];
    final totalAmountString = order['total_amount']?.toString() ?? "0";
    final double totalAmount = double.tryParse(totalAmountString) ?? 0.0;
    
    final status = order['status'] ?? 'UNKNOWN';
    final user = order['user'] ?? {};
    final userName = user['name'] ?? user['full_name'] ?? 'Unknown User';
    final orderId = order['id'];
    
    // Format date
    String dateStr = "";
    if (order['created_at'] != null) {
      try {
        final date = DateTime.parse(order['created_at']);
        dateStr = DateFormat('MMM d, h:mm a').format(date);
      } catch (e) {
        dateStr = "";
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#Order-$orderId",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'comfortaa',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF357D5D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF357D5D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'comfortaa',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'comfortaa',
            ),
          ),
          Text(
            "${items.length} items • ${NumberFormat.currency(symbol: 'RWF ').format(totalAmount)}",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'comfortaa',
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(orderId, status),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int orderId, String currentStatus) {
    if (currentStatus == "PENDING") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(orderId, "CANCELLED"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text("Reject", style: TextStyle(fontFamily: 'comfortaa')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(orderId, "CONFIRMED"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF357D5D),
              ),
              child: const Text("Confirm", style: TextStyle(fontFamily: 'comfortaa', color: Colors.white)),
            ),
          ),
        ],
      );
    } else if (currentStatus == "CONFIRMED") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(orderId, "PREPARING"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Start Preparing", style: TextStyle(color: Colors.white, fontFamily: 'comfortaa')),
        ),
      );
    } else if (currentStatus == "PREPARING") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(orderId, "OUT_FOR_DELIVERY"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Mark as Ready", style: TextStyle(color: Colors.white, fontFamily: 'comfortaa')),
        ),
      );
    } else if (currentStatus == "OUT_FOR_DELIVERY") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(orderId, "DELIVERED"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Mark as Delivered", style: TextStyle(color: Colors.white, fontFamily: 'comfortaa')),
        ),
      );
    } else if (currentStatus == "DELIVERED" || currentStatus == "CANCELLED") {
      // No actions for delivered or cancelled orders
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}
