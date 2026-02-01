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

  Future<void> _createCategory(String name, String description, int sortOrder, bool isActive) async {
    // Show loading or just wait
    // Ideally disable button in dialog
    
    // For now, we'll just handle the API call
    final result = await ApiClient.createCategory(
      name: name,
      description: description,
      sortOrder: sortOrder,
      isActive: isActive,
    );

    if (result['success']) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully')),
        );
        _loadCategories(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create category')),
        );
      }
    }
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final sortOrderController = TextEditingController(text: "1");
    bool isActive = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Create Category"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description"),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: sortOrderController,
                      decoration: const InputDecoration(labelText: "Sort Order"),
                      keyboardType: TextInputType.number,
                      validator: (value) => int.tryParse(value ?? "") == null ? "Must be a number" : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text("Active"),
                      value: isActive,
                      onChanged: (val) => setState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _createCategory(
                      nameController.text,
                      descController.text,
                      int.parse(sortOrderController.text),
                      isActive,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357D5D)),
                child: const Text("Create"),
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
          _showCreateCategoryDialog();
        },
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
