import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:intl/intl.dart';

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

  String _formatPrice(dynamic price) {
    if (price == null) return "0";
    double val = 0;
    if (price is String) {
      val = double.tryParse(price) ?? 0;
    } else if (price is num) {
      val = price.toDouble();
    }
    return val.toStringAsFixed(0);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'COMPLETED':
        return const Color(0xFF357D5D);
      case 'CANCELLED':
        return Colors.red;
      default:
        return const Color(0xFF357D5D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF357D5D)))
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF357D5D),
              child: _orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: const Text(
                          "No history yet",
                          style: TextStyle(fontFamily: 'comfortaa', fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final List<dynamic> items = order['items'] ?? [];
                        final DateTime date = order['created_at'] != null 
                            ? DateTime.parse(order['created_at']) 
                            : DateTime.now();
                        final String status = order['status'] ?? "PENDING";
                        final Color statusColor = _getStatusColor(status);

                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, y').format(date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'comfortaa',
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'comfortaa',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(color: Colors.grey[200]),
                              const SizedBox(height: 10),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${item['quantity']}x",
                                          style: const TextStyle(
                                            color: Color(0xFF357D5D),
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'comfortaa',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item['product_name'] ?? 'Unknown Item',
                                            style: const TextStyle(
                                              fontFamily: 'comfortaa',
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "RWF ${_formatPrice(item['total_price'])}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'comfortaa',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'comfortaa',
                                    ),
                                  ),
                                  Text(
                                    "RWF ${_formatPrice(order['total_amount'])}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF357D5D),
                                      fontFamily: 'comfortaa',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
