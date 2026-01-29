import 'package:mymeal/data/cart_manager.dart';

class Order {
  final List<CartItem> items;
  final DateTime date;
  final double totalPrice;

  Order({
    required this.items,
    required this.date,
    required this.totalPrice,
  });
}

class OrderManager {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  void placeOrder(List<CartItem> items, double total) {
    if (items.isEmpty) return;
    
    _orders.add(Order(
      items: List.from(items), // Create a copy of the list
      date: DateTime.now(),
      totalPrice: total,
    ));
    // In a real app, you might save this to a database here
  }
}

final orderManager = OrderManager();
