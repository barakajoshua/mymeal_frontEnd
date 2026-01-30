import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:mymeal/pages/manager/create_product_form.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllMenuItems();
    if (result['success']) {
      setState(() {
        _products = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to load products")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manage Products", style: TextStyle(color: Colors.black, fontFamily: 'comfortaa')),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final product = _products[index];
                // Parse price properly - it might come as String or number from API
                final priceValue = product['price'];
                final double price = priceValue is String 
                    ? double.tryParse(priceValue) ?? 0.0
                    : (priceValue is int ? priceValue.toDouble() : (priceValue ?? 0.0));
                
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: product['image_url'] != null
                          ? DecorationImage(image: NetworkImage(product['image_url']), fit: BoxFit.cover)
                          : null,
                    ),
                    child: product['image_url'] == null ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                  ),
                  title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${NumberFormat.currency(symbol: 'RWF ').format(price)}\n${product['description'] ?? ''}"),
                  isThreeLine: true,
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () {
                    // TODO: Open edit dialog
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductForm()),
          );
          
          // Refresh list if product was created
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
