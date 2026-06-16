import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:SS_Pool/ride/selection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Constants.dart'; // Import the constants file

import 'Terms.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;

  PhoneVerificationScreen({required this.phoneNumber, required this.email});

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _secureStorage = const FlutterSecureStorage();
  TextEditingController otpController = TextEditingController();
  bool isDisabled = false;

  Future<void> verifyOTP(BuildContext context, String otp) async {
    setState(() {
      isDisabled = true; // Disable button on click
    });

    try {
      final url = Uri.parse('${APIConstants.baseUrl}/verify');
      final response = await http.post(
        url,
        body: jsonEncode({'email': widget.email, 'otp': otp}),
        headers: {'Content-Type': 'application/json'},
      );

      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['message'] == 'OTP verified successfully') {
          final token = data['token'];
          await _secureStorage.write(key: 'jwt_token', value: token);
          var email = data['email'];
          var isDriver = data['isDriver'];
          var documents = data['documents'];

          final storedToken = await _secureStorage.read(key: 'jwt_token');
          print('Stored JWT Token: $storedToken');
          print('$isDriver isDriver');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RidePage(
                email: email,
                phoneNumber: widget.phoneNumber,
                isdriver: true,
                documents: documents,
              ),
            ),
          );
        } else {
          _showErrorDialog(context, data['message'] ?? 'Invalid OTP.');
          setState(() {
            isDisabled = false; // Re-enable button on failure
          });
        }
      } else {
        throw Exception(
            'Failed to verify OTP. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
      setState(() {
        isDisabled = false; // Re-enable button on failure
      });
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Center(
                  child: Image.asset('assets/verification.png'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "OTP Verification",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the OTP sent to your number",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () {
                        final otp = otpController.text.trim();
                        if (otp.isNotEmpty) {
                          verifyOTP(context, otp);
                        } else {
                          _showErrorDialog(context, 'Please enter the OTP.');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled
                      ? Colors.grey // Disabled color
                      : const Color.fromARGB(255, 0, 0, 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Verify",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Resend code logic
                },
                child: Text.rich(
                  TextSpan(
                    text: "Didn't get code? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      TextSpan(
                        text: "Resend it",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
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
