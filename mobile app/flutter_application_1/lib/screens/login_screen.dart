import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _factoryNameController = TextEditingController();
  final _localisationController = TextEditingController();
  final _fiscalMatriculeController = TextEditingController();
  final _energyCapacityController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _energySourceController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _factoryNameController.dispose();
    _localisationController.dispose();
    _fiscalMatriculeController.dispose();
    _energyCapacityController.dispose();
    _contactInfoController.dispose();
    _energySourceController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      const url = 'http://localhost:5000/login';
      print('Attempting to login with email: ${_emailController.text}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      print('Received response with status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Call onLogin callback to navigate to the app
        widget.onLogin();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('An error occurred during login: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'factory_name': _factoryNameController.text,
        'localisation': _localisationController.text,
        'fiscal_matricule': _fiscalMatriculeController.text,
        'energy_capacity': int.parse(_energyCapacityController.text),
        'contact_info': _contactInfoController.text,
        'energy_source': _energySourceController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      const url = 'http://localhost:5000/signup';
      print('Attempting to sign up with data: $data');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      print('Received response with status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factory registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLogin = true; // Switch to login screen on success
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register factory: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('An error occurred during sign up: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateForm() {
    if (!_isLogin) {
      // Validate required fields for sign-up
      if (_factoryNameController.text.trim().isEmpty) {
        return 'Factory Name is required';
      }
      if (_fiscalMatriculeController.text.trim().isEmpty) {
        return 'Fiscal Matricule is required';
      }
      if (_energyCapacityController.text.trim().isEmpty) {
        return 'Energy Capacity is required';
      }
      // Validate energy capacity is a valid number
      if (int.tryParse(_energyCapacityController.text.trim()) == null) {
        return 'Energy Capacity must be a valid number';
      }
      
      // For sign-up, validate password requirements
      if (_passwordController.text.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(_passwordController.text)) {
        return 'Password must contain at least one letter and one number';
      }
    }
    
    // Validate email for both login and sign-up
    if (_emailController.text.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailController.text.contains('@')) {
      return 'Please enter a valid email address';
    }
    
    // Validate password for both login and sign-up
    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    
    return null; // No errors
  }

  void _handleSubmit() {
    // Validate form before submission
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (_isLogin) {
      // Handle login logic
      _login();
    } else {
      // Handle sign-up logic
      _signUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0a0a0a),
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.grey.shade900.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'lib/screens/assets/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Next Gen Power',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Peer-to-Peer Energy Trading Platform',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Tabs
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isLogin = true),
                              style: TextButton.styleFrom(
                                backgroundColor: _isLogin
                                    ? Colors.grey.shade800
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isLogin = false),
                              style: TextButton.styleFrom(
                                backgroundColor: !_isLogin
                                    ? Colors.grey.shade800
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form
                      if (!_isLogin) ...[
                        TextField(
                          controller: _factoryNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Factory Name *',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _localisationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Localisation',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fiscalMatriculeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Fiscal Matricule *',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _energyCapacityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Energy Capacity',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactInfoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Contact Info',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _energySourceController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Energy Source',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          helperText: 'Min 8 characters, at least one letter and one number',
                          helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLogin
                                ? Colors.blue.shade600
                                : Colors.purple.shade600,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLogin
                                          ? 'Login to Dashboard'
                                          : 'Create Account',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'By logging in, you agree to our Terms of Service',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
