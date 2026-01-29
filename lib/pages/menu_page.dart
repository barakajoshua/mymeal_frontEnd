import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mymeal/models/product.dart';
import 'package:mymeal/widgets/product_detail_sheet.dart';
import 'package:mymeal/models/menu_item.dart' as model;
import 'package:mymeal/services/api_client.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCategory = 'All';
  String searchQuery = '';
  List<String> categories = ['All'];
  List<Product> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Fetch Categories
      print("DEBUG: Loading categories...");
      final catResult = await ApiClient.getCategories();
      print("DEBUG: Categories result keys: ${catResult.keys}");
      if (catResult['success'] == true && catResult['data'] != null) {
        final List<dynamic> catData = catResult['data'];
        final List<String> mappedCategories = catData
            .map((c) => (c['name'] ?? 'Unknown').toString())
            .toList();
        setState(() {
          categories = ['All', ...mappedCategories];
        });
        print("DEBUG: Categories list updated: $categories");
      } else {
        print("DEBUG: Failed to load categories: ${catResult['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load categories: ${catResult['message']}")),
          );
        }
      }

      // Fetch Menus
      print("DEBUG: Loading menus...");
      final menuResult = await ApiClient.getMenus();
      print("DEBUG: Menus result success: ${menuResult['success']}");
      if (menuResult['success'] == true && menuResult['data'] != null) {
        final List<dynamic> menuData = menuResult['data'];
        print("DEBUG: Menus raw data length: ${menuData.length}");
        final products = menuData.map((m) {
          try {
            return Product.fromMenuItem(model.MenuItem.fromJson(m));
          } catch (e) {
            print("DEBUG: Error parsing single menu item: $e");
            print("DEBUG: Item data: $m");
            return null;
          }
        }).whereType<Product>().toList();
        
        setState(() {
          allProducts = products;
        });
        print("DEBUG: Loaded ${allProducts.length} products total");
      } else {
        print("DEBUG: Failed to load menus or data null: ${menuResult['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load menus: ${menuResult['message']}")),
          );
        }
      }
    } catch (e) {
      print("DEBUG: Global error in _loadData: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Product> get filteredProducts {
    return allProducts.where((product) {
      final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Menu",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF32B768),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Our Food",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Text(
                "Special For You",
                style: TextStyle(
                  color: Color(0xFF32B768),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'comfortaa',
                ),
              ),
              const SizedBox(height: 15),
              // Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search Your Menus",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Categories
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                height: 2,
                                width: 20,
                                color: const Color(0xFF32B768),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Products Grid
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF32B768),
                        ),
                      )
                    : filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "No items found",
                              style: TextStyle(fontFamily: 'comfortaa', color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredProducts.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                            ),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => ProductDetailSheet(product: product),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          imageUrl: product.imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.restaurant, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "RWF ${product.price.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Color(0xFF32B768),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
