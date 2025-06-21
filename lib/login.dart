import 'package:flutter/material.dart';
import 'package:my_chat_app/registerpage.dart';
import 'package:my_chat_app/user_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // Required for the glass effect

import 'constants.dart';// Import the register page

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const LoginPage());
  }

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => UserListPage()),
            (route) => false,
      );
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unexpectedErrorMessage), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📷 Chat-themed Background
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1526554850534-7c78330d5f90?q=80&w=2069&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
              fit: BoxFit.cover,
            ),
          ),
          // 📝 Glassy Login Card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Enhanced blur effect
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // More transparent white overlay
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)), // Defined border
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Welcome Back! 👋",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Sign in to chat with friends",
                            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField("Email", _emailController, Icons.email),
                          const SizedBox(height: 15),
                          _buildTextField("Password", _passwordController, Icons.lock, isPassword: true),
                          const SizedBox(height: 20),
                          _buildLoginButton(),
                          const SizedBox(height: 15),
                          // 🔹 New Button to Navigate to Sign Up Page
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(RegisterPage.route(isRegistering: true));
                            },
                            child: const Text(
                              "Don't have an account? Sign Up",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔑 Custom Glassy Text Field
  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }

  // 🔥 Custom Login Button
  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Login',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
