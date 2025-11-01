import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement the logic for searching account by mobile number or sending reset code.
      // For now, just show a snackbar or navigate to verify code.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Continue with mobile: ${_mobileController.text}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Light blue background to match screenshot
      appBar: AppBar(
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find Your Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Enter your mobile number',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter your mobile number',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  // Optional: Add further phone validation here
                  return null;
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue, // Blue button
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                context.go('/forgot_password_email'); // Navigate to email-based reset screen
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.black54),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Search by email instead',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}