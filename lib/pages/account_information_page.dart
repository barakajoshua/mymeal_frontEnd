import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mymeal/widgets/otp_verification_dialog.dart';
import 'package:mymeal/services/api_client.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({super.key});

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController(text: "18 February, 2001");
    _locationController = TextEditingController(text: "Kigali, Rwanda");
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiClient.getUserData();
    if (data != null) {
      setState(() {
        _nameController.text = data['full_name'] ?? "";
        _emailController.text = data['email'] ?? "";
        _phoneController.text = data['phone_number'] ?? "";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSensitiveEdit(String fieldName, String currentValue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        contactInfo: _phoneController.text, // Use real phone number
        onVerified: () {
          // Allow editing after verification
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("$fieldName verified! You can now edit.")),
          );
          // Here you would typically enable the field or show an edit dialog
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2001, 2, 18), // Default to current value or now
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF357D5D), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF357D5D), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd MMMM, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profile",
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            Center(
              child: Stack(
                children: [
                   Container(
                     width: 120,
                     height: 120,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.grey[200]!, width: 2),
                       image: const DecorationImage(
                         image: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400&auto=format&fit=crop"),
                         fit: BoxFit.cover,
                       ),
                     ),
                   ),
                   Positioned(
                     bottom: 0,
                     right: 0,
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: const BoxDecoration(
                         color: Color(0xFF357D5D), // Green from design
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(
                         Icons.edit,
                         color: Colors.white,
                         size: 20,
                       ),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildInputField("Full Name", _nameController),
            _buildInputField("Date of Birth", _dobController, isDatePicker: true),
            _buildInputField("Location", _locationController, suffixIcon: Icons.location_on_outlined),
            _buildInputField("Email", _emailController, isSensitive: true),
            _buildInputField("Phone", _phoneController, isSensitive: true),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3238), // Dark color from design
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'comfortaa',
                  ),
                ),
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, 
    {bool isDatePicker = false, 
     IconData? suffixIcon,
     bool isSensitive = false,
    }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
            fontFamily: 'comfortaa',
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (isSensitive) {
              _handleSensitiveEdit(label, controller.text);
            } else if (isDatePicker) {
              _selectDate(context);
            }
          },
          child: AbsorbPointer(
            absorbing: isSensitive || isDatePicker, // Prevent direct editing for sensitive fields and date picker
            child: TextField(
              controller: controller,
              readOnly: isDatePicker, // Date picker usually read only text field
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50], // Very light grey
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF357D5D)),
                ),
                suffixIcon: isDatePicker 
                    ? const Icon(Icons.calendar_today_outlined, color: Colors.grey)
                    : isSensitive 
                        ? const Icon(Icons.edit, color: Color(0xFF357D5D)) // Green highlight
                        : Icon(suffixIcon ?? Icons.edit, color: Colors.grey),
              ),
              style: const TextStyle(
                fontFamily: 'comfortaa',
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
