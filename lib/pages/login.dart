import 'package:flutter/material.dart';
import 'package:mymeal/pages/profile.dart';
import 'package:mymeal/pages/forgot_password.dart';
import 'package:mymeal/pages/signup.dart';
import 'package:mymeal/pages/congratulation.dart';
import 'package:mymeal/pages/main_screen.dart';
import 'package:mymeal/pages/manager/manager_dashboard.dart';
import 'package:mymeal/pages/developer/developer_dashboard.dart';
import 'package:mymeal/models/user_role.dart';
import 'package:mymeal/services/api_client.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiClient.login(
      phoneNumber: phoneController.text,
      password: passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        final userData = result['data']['user'];
        // API response uses 'role_id' in user object, ensure we parse it correctly
        final int roleId = userData['roleId'] ?? userData['role_id'] ?? 1;

        Widget nextScreen;
        if (roleId == UserRole.manager) { // 3
          nextScreen = const ManagerDashboard();
        } else if (roleId == UserRole.developer) { // 2
          nextScreen = const DeveloperDashboard();
        } else if (roleId == UserRole.customer) { // 1
          nextScreen = const MainScreen();
        } else {
          // Chefs (4) or unknown roles don't have a mobile dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Access restricted: This role does not have a mobile dashboard.")),
          );
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login failed")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'comfortaa',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Sign in to your account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF357D5D),
                      fontFamily: 'comfortaa',
                    ),
                  ),
                  SizedBox(height: 60),

                  // Phone Number Field
                  Text(
                    "Phone Number",
                    style: TextStyle(
                      fontFamily: 'comfortaa',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+250...",
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Password Field
                  Text(
                    "Password",
                    style: TextStyle(
                      fontFamily: 'comfortaa',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "User Password",
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Forgot Password
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPassword()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF357D5D),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'comfortaa',
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Sign In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 60),
                      backgroundColor: Color(0xFF357D5D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Sign In",
                            style: TextStyle(
                              fontFamily: 'comfortaa',
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(height: 32),
                ],
              ),

              // Sign Up text
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUp()),
                  );
                },
                child: Text(
                  "Don't have an account? Sign Up",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'comfortaa',
                    color: Color(0xFF357D5D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Or Divider
              Row(
                children: [
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  SizedBox(width: 10),
                  Text(
                    "Or with",
                    style: TextStyle(
                      fontFamily: 'comfortaa',
                      color: const Color(0xFF357D5D),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 32),

              // Google Sign In
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF357D5D)),
                    minimumSize: Size(double.infinity, 60),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(width: 25),
                      Text(
                        "Sign in with Google",
                        style: TextStyle(
                          fontFamily: 'comfortaa',
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
