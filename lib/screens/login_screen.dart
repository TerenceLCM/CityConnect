import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Future<void> _login() async {
  //   if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
  //     setState(() => _errorMessage = 'Email and password are required');
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     final result = await ApiService.login(
  //       email: _emailController.text,
  //       password: _passwordController.text,
  //     );

  //     if (result['success'] == true && result['token'] != null) {
  //       // Save token locally
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('auth_token', result['token']);
  //       await prefs.setString('user_id', result['userId'] ?? '');
  //       await prefs.setString('username', result['username'] ?? '');

  //       if (mounted) {
  //         // Navigate to home screen
  //         Navigator.of(context).pushReplacementNamed('/home');
  //       }
  //     } else {
  //       setState(() => _errorMessage = result['message'] ?? 'Login failed');
  //     }
  //   } catch (e) {
  //     setState(() => _errorMessage = 'Error: $e');
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _login() async {
    print("LOGIN BUTTON CLICKED");

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      print("Email or password empty");
      setState(() => _errorMessage = 'Email and password are required');
      return;
    }

    print("Email: ${_emailController.text}");
    print("Password: ${_passwordController.text}");

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("Calling API login...");

      final result = await ApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      print("API Response: $result");

      if (result['success'] == true && result['token'] != null) {
        print("Login SUCCESS. Token: ${result['token']}");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['token']);

        print("Token saved. Navigating to home...");

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        print("Login failed: ${result['message']}");
        setState(() => _errorMessage = result['message'] ?? 'Login failed');
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      print("Login finished (finally)");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email and password are required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.signup(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (result['success'] == true && result['token'] != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['token']);
        await prefs.setString('user_id', result['userId'] ?? '');
        await prefs.setString('username', result['username'] ?? '');

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() => _errorMessage = result['message'] ?? 'Signup failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
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
    final accessibility = Provider.of<AccessibilityService>(context);
    final fontScale = accessibility.fontSizeMultiplier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highContrast = accessibility.highContrast;
    final touchTargetSize = accessibility.largeTouchTargets ? 80.0 : 60.0;

    final backgroundColor = highContrast
        ? (isDarkMode ? Colors.black : Colors.white)
        : (isDarkMode ? const Color(0xFF151718) : Colors.white);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'CityConnect',
                      style: TextStyle(
                        fontSize: 36 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart City Companion',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Email Field
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 16 * fontScale),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(fontSize: 16 * fontScale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 24),

              // Password Field
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(fontSize: 16 * fontScale),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(fontSize: 16 * fontScale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14 * fontScale,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: touchTargetSize,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Signup Button
              SizedBox(
                width: double.infinity,
                height: touchTargetSize,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Demo Credentials
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Credentials',
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: demo@example.com\nPassword: demo123',
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        color: textColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
