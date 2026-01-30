import 'package:flutter/material.dart';
import 'package:mymeal/pages/manager/manage_categories.dart';
import 'package:mymeal/pages/manager/manage_products.dart';
class ManagerMenu extends StatelessWidget {
  const ManagerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Menu Management",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildMenuSection(
            context,
            title: "Categories",
            description: "Manage food categories",
            icon: Icons.category,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCategories()));
            },
          ),
          const SizedBox(height: 16),
          _buildMenuSection(
            context,
            title: "Products",
            description: "Manage food items, prices and availability",
            icon: Icons.fastfood,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProducts()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF357D5D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF357D5D), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
