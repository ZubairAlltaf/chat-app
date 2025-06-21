import 'package:flutter/material.dart';
import 'package:my_chat_app/user_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // Required for the glass effect

import 'constants.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) {
    return MaterialPageRoute(
      builder: (context) => RegisterPage(isRegistering: isRegistering),
    );
  }

  final bool isRegistering;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      if (response.user == null) {
        throw AuthException('Signup failed: No user returned');
      }

      // Wait briefly to ensure the database trigger creates the profile
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => UserListPage()),
              (route) => false,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      print('Signup error: $error'); // Log for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign up: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📷 Chat-themed Background (NO Blur)
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1526554850534-7c78330d5f90?q=80&w=2069&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
              fit: BoxFit.cover,
            ),
          ),
          // 📝 Enhanced Glassy Registration Card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Increased blur effect
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Enhanced transparency
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)), // More defined border
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
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Create Account ✨",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Sign up to start chatting",
                            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField("Username", _usernameController, Icons.person),
                          const SizedBox(height: 15),
                          _buildTextField("Email", _emailController, Icons.email),
                          const SizedBox(height: 15),
                          _buildTextField("Password", _passwordController, Icons.lock, isPassword: true),
                          const SizedBox(height: 20),
                          _buildRegisterButton(),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(LoginPage.route());
                            },
                            child: const Text(
                              "Already have an account? Login",
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
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        if (isPassword && val.length < 6) return '6 characters minimum';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2), // More glassy effect
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)), // More defined border
        ),
      ),
    );
  }

  // 🔥 Custom Register Button
  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Sign Up',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
