import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:mymeal/pages/manager/create_chef_form.dart';

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

  Future<void> _updateChefStatus(Map<String, dynamic> chef, bool newStatus) async {
    final result = await ApiClient.updateChef(
      chefId: chef['id'],
      userId: chef['user_id'],
      displayName: chef['display_name'] ?? '',
      specialty: chef['specialty'] ?? '',
      bio: chef['bio'] ?? '',
      experienceYears: chef['experience_years'] ?? 0,
      isActive: newStatus,
    );

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chef status updated to ${newStatus ? "active" : "inactive"}')),
        );
        _loadChefs(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update chef status')),
        );
        _loadChefs(); // Refresh to revert UI change
      }
    }
  }

  Future<void> _showConfirmStatusDialog(Map<String, dynamic> chef, bool newStatus) async {
    final chefName = chef['display_name'] ?? 'this chef';
    final statusText = newStatus ? 'activate' : 'deactivate';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change', style: TextStyle(fontFamily: 'comfortaa', fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to $statusText $chefName?',
          style: const TextStyle(fontFamily: 'comfortaa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF357D5D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateChefStatus(chef, newStatus);
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
                              chef['display_name'] ?? user['full_name'] ?? 'Unknown Chef',
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
                        value: chef['is_active'] == 1 || chef['is_active'] == true,
                        activeColor: const Color(0xFF357D5D),
                        onChanged: (val) {
                          _showConfirmStatusDialog(chef, val);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateChefForm()),
          );
          
          // Refresh list if chef was created
          if (result == true) {
            _loadChefs();
          }
        },
        backgroundColor: const Color(0xFF357D5D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
