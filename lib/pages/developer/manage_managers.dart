import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';

class ManageManagers extends StatefulWidget {
  const ManageManagers({super.key});

  @override
  State<ManageManagers> createState() => _ManageManagersState();
}

class _ManageManagersState extends State<ManageManagers> {
  // Placeholder list since we don't have explicit listing endpoint logic yet
  // Ideally this would fetch from /admin/managers or similar
  final List<dynamic> _managers = [
    {'name': 'Manager One', 'email': 'manager1@example.com', 'isActive': true},
  ];

  Future<void> _showAddManagerDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register Manager', style: TextStyle(fontFamily: 'comfortaa', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _registerManager(
                  nameController.text,
                  emailController.text,
                  phoneController.text,
                  passwordController.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF357D5D)),
              child: const Text('Register', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerManager(String name, String email, String phone, String password) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registering manager...")),
    );

    final result = await ApiClient.registerManager(
      fullName: name,
      phoneNumber: phone,
      email: email,
      password: password,
    );

    if (result['success']) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Manager registered successfully!")),
      );
      // Ideally refresh list here
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Registration failed")),
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
        title: const Text(
          "Managers",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _managers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final manager = _managers[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'comfortaa',
                        ),
                      ),
                      Text(
                        manager['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'comfortaa',
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: manager['isActive'],
                  activeColor: const Color(0xFF357D5D),
                  onChanged: (val) {},
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManagerDialog,
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
