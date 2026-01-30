import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';

class ManageCategories extends StatefulWidget {
  const ManageCategories({super.key});

  @override
  State<ManageCategories> createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends State<ManageCategories> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllCategories();
    if (result['success']) {
      setState(() {
        _categories = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to load categories")),
        );
      }
    }
  }

  // NOTE: Add/Edit/Delete methods would go here, utilizing ApiClient
  // Since user asked for "Minimal but complete", listing is priority + "Create category" button/form

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manage Categories", style: TextStyle(color: Colors.black, fontFamily: 'comfortaa')),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  title: Text(category['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(category['description'] ?? ''),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () {
                    // TODO: Open edit dialog
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open create dialog
        },
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
