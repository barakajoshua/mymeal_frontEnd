import 'package:flutter/material.dart';

class DeveloperHome extends StatelessWidget {
  const DeveloperHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Admin Panel",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'comfortaa',
              ),
            ),
            const SizedBox(height: 32),
            _buildStatCard(
              title: "Total Managers",
              count: "4",
              color: Colors.blue,
              icon: Icons.people,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: "Active Managers",
              count: "3",
              color: Colors.green,
              icon: Icons.verified_user,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'comfortaa',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'comfortaa',
                ),
              ),
            ],
          ),
          Icon(icon, color: color, size: 40),
        ],
      ),
    );
  }
}
