import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/signup_page.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userService = Provider.of<UserService>(context, listen: false);
    final success = await userService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Placeholder for Google Sign-In logic
  Future<void> _handleGoogleSignIn() async {
    // TODO: Implement full Google Sign-In logic using the 'google_sign_in' package.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In is not yet implemented.')),
    );
  }

  // Placeholder for Apple Sign-In logic
  Future<void> _handleAppleSignIn() async {
    // TODO: Implement full Apple Sign-In logic using the 'sign_in_with_apple' package.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In is not yet implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue your learning journey.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Username or Email'),
                  validator: (value) => value!.isEmpty ? 'Please enter a username or email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                  ),
                  obscureText: _isPasswordObscured,
                  validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 24),
                _buildSocialDivider(),
                const SizedBox(height: 24),
                // Google Sign-In Button
                _buildGoogleButton(),
                // Apple Sign-In Button (only shown on Apple platforms)
                if (Platform.isIOS || Platform.isMacOS) ...[
                  const SizedBox(height: 16),
                  _buildAppleButton(),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to the SignUpPage
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignUpPage()));
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: const FaIcon(FontAwesomeIcons.google, size: 20.0),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    return ElevatedButton.icon(
      onPressed: _handleAppleSignIn,
      icon: const Icon(Icons.apple, color: Colors.white),
      label: const Text('Continue with Apple'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}