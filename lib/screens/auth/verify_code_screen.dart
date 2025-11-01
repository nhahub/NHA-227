import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerifyCodeScreen extends StatefulWidget {
  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  // Controllers for each digit
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());

  // Focus nodes to shift focus automatically
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  // Track code input
  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    _focusNodes.forEach((f) => f.dispose());
    super.dispose();
  }

  void _onContinue() {
    if (_code.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all 5 digits.')),
      );
      return;
    }
    // TODO: Verify the code via your backend or Firebase logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code entered: $_code')),
    );
  }

  void _onResendCode() {
    // TODO: Add resend code logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resend code clicked')),
    );
  }

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 50,
      height: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 4) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Code'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) => _buildCodeBox(index)),
            ),
            SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter 5 digit code',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'A five-digit code should have come to your email address that you indicated.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),

            SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _onResendCode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.green, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Resend code',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _onContinue,
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}