import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:mymeal/pages/login.dart';

class DeveloperProfile extends StatelessWidget {
  const DeveloperProfile({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await ApiClient.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "System Administrator",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'comfortaa',
              ),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'comfortaa',
                ),
              ),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
