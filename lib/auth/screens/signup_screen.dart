import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  // final _cnicController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_nameController.text.trim().isEmpty ||
        email.isEmpty ||
        _mobileController.text.trim().isEmpty ||
        // _cnicController.text.trim().isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    // Corrected email regex pattern
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return false;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to Terms & Conditions')),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveUserData(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'email': user.email,
      'mobile': _mobileController.text.trim(),
      // 'cnic': _cnicController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _signup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    debugPrint(
      '[Signup] Starting signup process with email: ${_emailController.text.trim()}',
    );

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint('[Signup] Firebase Auth account created.');

      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      debugPrint('[Signup] Display name updated.');

      await _saveUserData(userCredential.user!);
      debugPrint('[Signup] Firestore user profile saved.');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signup successful!')));

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Signup] FirebaseAuthException: ${e.code}');

      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') message = 'Email already in use';
      if (e.code == 'invalid-email') message = 'Invalid email address';
      if (e.code == 'weak-password') message = 'Password is too weak';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('[Signup] Unknown error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      debugPrint('[Signup] Signup process completed.');
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    Size size,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.015),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(fontSize: size.width * 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width * 0.06,
      vertical: size.height * 0.05,
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF2E6D6A),
          height: size.height,
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Spendly',
                  style: TextStyle(
                    fontSize: size.width * 0.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(_nameController, 'Full Name', size),
                _buildTextField(_emailController, 'Email', size),
                _buildTextField(_mobileController, 'Mobile Number', size),
                // _buildTextField(_cnicController, 'CNIC', size),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.02,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: Colors.white,
                      checkColor: const Color(0xFF5BA29C),
                      side: const BorderSide(color: Colors.white),
                      onChanged:
                          (value) =>
                              setState(() => _agreedToTerms = value ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I agree with Terms & Conditions',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.06,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BA29C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            )
                            : const Text(
                              'SIGNUP',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
