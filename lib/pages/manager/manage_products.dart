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

  Future<void> _updateProduct(int id, String name, double price, bool isAvailable) async {
    // Show loading indicator in dialog or generally?
    // For simplicity, close dialog then show global loading or waiting.
    
    final result = await ApiClient.updateProduct(
      productId: id,
      name: name,
      price: price,
      isAvailable: isAvailable,
    );

    if (result['success']) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        _loadProducts(); // Refresh list
      }
    } else {
      // Keep dialog open? or close and show error?
      // Let's show error on top of dialog if possible, or close and show snackbar.
      // Closing is safer to avoid context issues.
       if (mounted) {
        // Navigator.pop(context); // Optional: keep open to let user retry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update product')),
        );
      }
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final TextEditingController nameController = TextEditingController(text: product['name']);
    
    // Parse price safely for initial value
    final priceValue = product['price'];
    final double initialPrice = priceValue is String 
        ? double.tryParse(priceValue) ?? 0.0
        : (priceValue is int ? priceValue.toDouble() : (priceValue ?? 0.0));
        
    final TextEditingController priceController = TextEditingController(text: initialPrice.toString());
    
    // Handle is_available. API returns it as boolean usually, strictly check.
    // Sometimes it might be 1/0 or "1"/"0" or true/false.
    bool isAvailable = product['is_available'] == true || product['is_available'] == 1 || product['is_available'] == "1";

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Product", style: TextStyle(fontFamily: 'comfortaa', fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixText: "RWF",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => double.tryParse(value ?? "") == null ? "Must be a number" : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Available"),
                      value: isAvailable,
                      activeColor: const Color(0xFF357D5D),
                      onChanged: (val) => setState(() => isAvailable = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _updateProduct(
                      product['id'],
                      nameController.text,
                      double.parse(priceController.text),
                      isAvailable,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF357D5D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
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
                    _showEditProductDialog(product);
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
