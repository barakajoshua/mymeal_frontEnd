import 'package:flutter/material.dart';
import 'package:mymeal/models/product.dart';

class CartItem {
  final Product product;
  int quantity;
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
    // Check if item already exists with same sauces
    final existingIndex = _items.indexWhere((item) => 
      item.product.id == product.id && 
      _areSaucesEqual(item.sauces, sauces)
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        sauces: List<String>.from(sauces ?? []),
      ));
    }
    _notifyListeners();
  }

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: 1,
        sauces: [],
      ));
    }
    _notifyListeners();
  }

  void removeItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity--;
      } else {
        _items.removeAt(existingIndex);
      }
      _notifyListeners();
    }
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

  bool _areSaucesEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (var element in list1) {
      if (!list2.contains(element)) return false;
    }
    return true;
  }
}

final cartManager = CartManager();
