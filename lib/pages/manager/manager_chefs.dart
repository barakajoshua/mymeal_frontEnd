import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';

class ManagerChefs extends StatefulWidget {
  const ManagerChefs({super.key});

  @override
  State<ManagerChefs> createState() => _ManagerChefsState();
}

class _ManagerChefsState extends State<ManagerChefs> {
  List<dynamic> _chefs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChefs();
  }

  Future<void> _loadChefs() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getAllChefs();
    if (result['success']) {
      setState(() {
        _chefs = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to load chefs")),
        );
      }
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
          "Chefs",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _chefs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final chef = _chefs[index];
                final user = chef['user'] ?? {};
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
                              chef['displayName'] ?? user['full_name'] ?? 'Unknown Chef',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'comfortaa',
                              ),
                            ),
                            Text(
                              chef['specialty'] ?? "Cuisine",
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
                        value: chef['isActive'] == 1 || chef['isActive'] == true,
                        activeColor: const Color(0xFF357D5D),
                        onChanged: (val) {},
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Add Chef Flow (Register user + Create Chef Profile)
        },
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
