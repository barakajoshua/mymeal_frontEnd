import 'package:flutter/material.dart';
import 'package:mymeal/pages/history_page.dart';
import 'package:mymeal/pages/account_information_page.dart';
import 'package:mymeal/pages/login.dart';
import 'package:mymeal/services/api_client.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiClient.getUserData();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await ApiClient.logout();
    if (mounted) {
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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: const Color(0xFF357D5D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                          "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop"),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _userData?['full_name'] ?? "User",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'comfortaa'),
                    ),
                    Text(
                      _userData?['email'] ?? _userData?['phone_number'] ?? "No contact info",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    _buildProfileOption(
                      Icons.person_outline,
                      "Account Information",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountInformationPage()),
                        );
                      },
                    ),
                    _buildProfileOption(
                      Icons.history,
                      "Order History",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryPage()),
                        );
                      },
                    ),
                    _buildProfileOption(Icons.payment, "Payment Method"),
                    _buildProfileOption(Icons.settings_outlined, "Settings"),
                    _buildProfileOption(Icons.help_outline, "Help & Support"),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _handleLogout,
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF357D5D)),
      title: Text(title, style: const TextStyle(fontFamily: 'comfortaa')),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}