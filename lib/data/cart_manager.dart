import 'package:flutter/material.dart';
import 'package:mymeal/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final List<String> sauces;

  CartItem({
    required this.product,
    required this.quantity,
    required this.sauces,
  });
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  final List<VoidCallback> _listeners = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  void addToCart(Product product, int quantity, List<String> sauces) {
    _items.add(CartItem(
      product: product,
      quantity: quantity,
      sauces: List<String>.from(sauces ?? []),
    ));
    _notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

final cartManager = CartManager();
