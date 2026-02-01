import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateProductForm extends StatefulWidget {
  const CreateProductForm({super.key});

  @override
  State<CreateProductForm> createState() => _CreateProductFormState();
}

class _CreateProductFormState extends State<CreateProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  int? _selectedCategoryId;
  int? _selectedChefId;
  DateTime _selectedDate = DateTime.now();
  bool _isAvailable = true;
  bool _isLoading = false;
  
  List<dynamic> _categories = [];
  List<dynamic> _chefs = [];
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    print('DEBUG: Loading categories and chefs...');
    final categoriesResult = await ApiClient.getAllCategories();
    final chefsResult = await ApiClient.getAllChefs();
    
    print('DEBUG: Categories result: ${categoriesResult['success']}');
    print('DEBUG: Categories data: ${categoriesResult['data']}');
    print('DEBUG: Chefs result: ${chefsResult['success']}');
    print('DEBUG: Chefs data: ${chefsResult['data']}');
    
    if (categoriesResult['success']) {
      setState(() {
        _categories = categoriesResult['data'] ?? [];
        print('DEBUG: Loaded ${_categories.length} categories');
      });
    } else {
      print('DEBUG: Failed to load categories: ${categoriesResult['message']}');
    }
    
    if (chefsResult['success']) {
      setState(() {
        _chefs = chefsResult['data'] ?? [];
        print('DEBUG: Loaded ${_chefs.length} chefs');
      });
    } else {
      print('DEBUG: Failed to load chefs: ${chefsResult['message']}');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          // Limit to 5 images total
          final remainingSlots = 5 - _selectedImages.length;
          final imagesToAdd = images.take(remainingSlots).map((xFile) => File(xFile.path)).toList();
          _selectedImages.addAll(imagesToAdd);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedChefId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chef')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiClient.createProduct(
      categoryId: _selectedCategoryId!,
      chefId: _selectedChefId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      availableDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      isAvailable: _isAvailable,
      images: _selectedImages,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
          'Create Product',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: _isLoading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name *',
                        labelStyle: const TextStyle(fontFamily: 'comfortaa'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        labelStyle: const TextStyle(fontFamily: 'comfortaa'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (RWF) *',
                        labelStyle: const TextStyle(fontFamily: 'comfortaa'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        labelStyle: const TextStyle(fontFamily: 'comfortaa'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(
                            category['name'] ?? '',
                            style: const TextStyle(fontFamily: 'comfortaa'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Chef Dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedChefId,
                      decoration: InputDecoration(
                        labelText: 'Chef *',
                        labelStyle: const TextStyle(fontFamily: 'comfortaa'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _chefs.map((chef) {
                        return DropdownMenuItem<int>(
                          value: chef['id'],
                          child: Text(
                            chef['display_name'] ?? '',
                            style: const TextStyle(fontFamily: 'comfortaa'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChefId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Available Date
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                              style: const TextStyle(fontFamily: 'comfortaa'),
                            ),
                            const Icon(Icons.calendar_today, color: Color(0xFF357D5D)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Is Available Switch
                    SwitchListTile(
                      title: const Text(
                        'Available for Order',
                        style: TextStyle(fontFamily: 'comfortaa'),
                      ),
                      value: _isAvailable,
                      activeColor: const Color(0xFF357D5D),
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Images Section
                    const Text(
                      'Product Images *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'comfortaa',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add up to 5 images (at least 1 required)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'comfortaa',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image Grid
                    if (_selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 12),

                    // Add Images Button
                    if (_selectedImages.length < 5)
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(
                          _selectedImages.isEmpty ? 'Add Images' : 'Add More Images',
                          style: const TextStyle(fontFamily: 'comfortaa'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF357D5D),
                          side: const BorderSide(color: Color(0xFF357D5D)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF357D5D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'comfortaa',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}