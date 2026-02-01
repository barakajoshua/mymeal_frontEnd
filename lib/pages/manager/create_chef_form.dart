import 'package:flutter/material.dart';
import 'package:mymeal/services/api_client.dart';

class CreateChefForm extends StatefulWidget {
  const CreateChefForm({super.key});

  @override
  State<CreateChefForm> createState() => _CreateChefFormState();
}

class _CreateChefFormState extends State<CreateChefForm> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 1: User Account fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Step 2: Chef Profile fields
  final _displayNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  
  int? _createdUserId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _createUserAccount() async {
    if (!_formKey1.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiClient.register(
      fullName: _fullNameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
      roleId: 4, // Chef role
      includeDeviceToken: false, // Don't include device token for chef registration
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Extract user ID from response
      _createdUserId = result['data']['user']['id'];
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User account created successfully')),
        );
        setState(() => _currentStep = 1);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create user account')),
        );
      }
    }
  }

  Future<void> _createChefProfile() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_createdUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please go back and create user account first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiClient.createChefProfile(
      userId: _createdUserId!,
      displayName: _displayNameController.text,
      specialty: _specialtyController.text,
      bio: _bioController.text,
      experienceYears: int.parse(_experienceYearsController.text),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chef profile created successfully')),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create chef profile')),
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
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Create Chef',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'comfortaa',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Stack(
            children: [
              // Background track
              Container(
                height: 4,
                color: Colors.grey[200],
              ),
              // Animated progress bar
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                tween: Tween<double>(
                  begin: 0,
                  end: _currentStep == 0 ? 0.5 : 1.0,
                ),
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF357D5D),
                          const Color(0xFF357D5D).withOpacity(0.7),
                          const Color(0xFF357D5D),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: _ShimmerEffect(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF357D5D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF357D5D),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_currentStep + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'comfortaa',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _currentStep == 0 ? 'User Account' : 'Chef Profile',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'comfortaa',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Step ${_currentStep + 1}/2',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'comfortaa',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Step content
                  if (_currentStep == 0) ...[
                    // Step 1: User Account
                    Form(
                      key: _formKey1,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.phone),
                              hintText: '+250780000000',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (!value.startsWith('+')) return 'Phone must start with +';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (!value.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Step 2: Chef Profile
                    Form(
                      key: _formKey2,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.badge),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specialtyController,
                            decoration: InputDecoration(
                              labelText: 'Specialty',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.restaurant),
                              hintText: 'e.g., French Cuisine',
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bioController,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.description),
                              hintText: 'Tell us about the chef...',
                            ),
                            maxLines: 3,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _experienceYearsController,
                            decoration: InputDecoration(
                              labelText: 'Years of Experience',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.work),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (int.tryParse(value) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentStep == 0) {
                              _createUserAccount();
                            } else {
                              _createChefProfile();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF357D5D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentStep == 1 ? 'Create Chef' : 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'comfortaa',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep -= 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          _currentStep == 0 ? 'Cancel' : 'Back',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'comfortaa',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// Shimmer effect widget for the progress bar
class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}
