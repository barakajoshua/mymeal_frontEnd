import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  bool _isLoading = true;
  int _pendingCount = 0;
  int _preparingCount = 0;
  int _onWayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderCounts();
  }

  Future<void> _loadOrderCounts() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllOrders();
    
    if (result['success']) {
      final orders = result['data'] as List<dynamic>? ?? [];
      
      int pending = 0;
      int preparing = 0;
      int onWay = 0;
      
      for (var order in orders) {
        final status = (order['status'] ?? '').toString().toUpperCase();
        if (status == 'PENDING') {
          pending++;
        } else if (status == 'PREPARING') {
          preparing++;
        } else if (status == 'OUT_FOR_DELIVERY') {
          onWay++;
        }
      }
      
      setState(() {
        _pendingCount = pending;
        _preparingCount = preparing;
        _onWayCount = onWay;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToOrders(int tabIndex) {
    // Navigate to ManagerOrders and switch to specific tab
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerOrdersWithTab(initialTabIndex: tabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrderCounts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Good evening, Manager",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'comfortaa',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Here's what's happening today",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'comfortaa',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSummaryCard(
                      context,
                      title: "Pending Orders",
                      count: "$_pendingCount",
                      color: Colors.orange,
                      icon: Icons.timer,
                      onTap: () => _navigateToOrders(0), // Tab index 0 = PENDING
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      title: "Preparing",
                      count: "$_preparingCount",
                      color: Colors.blue,
                      icon: Icons.soup_kitchen,
                      onTap: () => _navigateToOrders(2), // Tab index 2 = PREPARING
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      title: "Ready for Pickup",
                      count: "$_onWayCount",
                      color: Colors.green,
                      icon: Icons.check_circle,
                      onTap: () => _navigateToOrders(3), // Tab index 3 = READY
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget to accept initial tab index
class ManagerOrdersWithTab extends StatefulWidget {
  final int initialTabIndex;
  
  const ManagerOrdersWithTab({super.key, required this.initialTabIndex});

  @override
  State<ManagerOrdersWithTab> createState() => _ManagerOrdersWithTabState();
}

class _ManagerOrdersWithTabState extends State<ManagerOrdersWithTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allOrders = [];
  bool _isLoading = true;

  final List<String> _tabs = [
    "PENDING",
    "CONFIRMED",
    "PREPARING",
    "READY",
    "COMPLETED",
    "CANCELLED"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllOrders();
    if (result['success']) {
      setState(() {
        _allOrders = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final result = await ApiClient.updateOrderStatus(orderId, newStatus);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order updated to $newStatus")),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to update status")),
      );
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
        leading: const BackButton(color: Colors.black),
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
          tabs: _tabs.map((tab) => Tab(text: tab.replaceAll('_', ' '))).toList(),
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
    final items = order['items'] as List<dynamic>? ?? [];
    final totalAmountString = order['total_amount']?.toString() ?? "0";
    final double totalAmount = double.tryParse(totalAmountString) ?? 0.0;
    
    final status = order['status'] ?? 'UNKNOWN';
    final user = order['user'] ?? {};
    final userName = user['name'] ?? user['full_name'] ?? 'Unknown User';
    final orderId = order['id'];
    
    String dateStr = "";
    if (order['created_at'] != null) {
      try {
        final date = DateTime.parse(order['created_at']);
        dateStr = "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
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
            "${items.length} items • RWF ${totalAmount.toStringAsFixed(0)}",
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
          onPressed: () => _updateStatus(orderId, "READY"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Mark as Ready", style: TextStyle(color: Colors.white, fontFamily: 'comfortaa')),
        ),
      );
    } else if (currentStatus == "READY") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(orderId, "COMPLETED"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Mark Completed", style: TextStyle(color: Colors.white, fontFamily: 'comfortaa')),
        ),
      );
    } else if (currentStatus == "COMPLETED" || currentStatus == "CANCELLED") {
      // No actions for completed or cancelled orders
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}
