import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isOtpSent = false;

  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF6B46C1)),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app.AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF6B46C1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.login, size: 50, color: Colors.white),
              ),
              SizedBox(height: 40),

              Text(
                _isOtpSent ? 'Enter OTP' : 'Login with Mobile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                _isOtpSent
                    ? 'OTP sent to +91 ${_phoneController.text}'
                    : 'Enter your mobile number to continue',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              if (!_isOtpSent) ...[
                // Phone Input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _sendOTP(authProvider),
                  child: authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Send OTP'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Color(0xFF6B46C1),
                  ),
                ),
              ] else ...[
                // OTP Input
                Pinput(
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  onCompleted: (pin) => _verifyOTP(pin, authProvider),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => _resendOTP(authProvider),
                  child: Text('Resend OTP'),
                ),
              ],

              SizedBox(height: 20),

              // Google Login Option
              if (!_isOtpSent) ...[
                Text('OR', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    // Implement Google Sign-In
                  },
                  icon: Icon(Icons.g_mobiledata, size: 30),
                  label: Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOTP(app.AuthProvider authProvider) async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter valid 10-digit mobile number')),
      );
      return;
    }

    try {
      await authProvider.loginWithPhone(_phoneController.text);
      setState(() {
        _isOtpSent = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _verifyOTP(String otp, app.AuthProvider authProvider) async {
    String? error = await authProvider.verifyOTP(otp);

    if (error == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _resendOTP(app.AuthProvider authProvider) {
    _sendOTP(authProvider);
  }
}
