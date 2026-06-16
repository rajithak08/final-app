import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:SS_Pool/authentication/OTPVerification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../Constants.dart';
import 'package:SS_Pool/ride/selection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("SignUpScreen initialized");
    _performInitialVerification();
  }

  Future<void> _performInitialVerification() async {
    setState(() {
      _isLoading = true;
    });
    await _checkVerificationInBackground();
  }

 
Future<void> sendOtp(
    String phoneNumber, String email, BuildContext context) async {
  print("Attempting to send OTP - Phone: $phoneNumber, Email: $email");

  setState(() {
    _isLoading = true;
  });

  try {
    // Get the FCM token
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();

    if (fcmToken == null) {
      print("Failed to retrieve FCM token.");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to retrieve FCM token. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print("FCM Token: $fcmToken");

    final url = '${APIConstants.baseUrl}/email';
    print("Making OTP request to: $url");

    // Make the request with the FCM token
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phoneNumber,
        'email': email,
        'fcmToken': fcmToken, // Include the FCM token
      }),
    );

    print("OTP Response Status: ${response.statusCode}");
    print("OTP Response Body: ${response.body}");

    if (response.statusCode == 200) {
      print("OTP sent successfully");
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneVerificationScreen(
            phoneNumber: phoneNumber,
            email: email,
          ),
        ),
      );
    } else {
      print("Failed to send OTP: ${response.statusCode}");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP. Status: ${response.statusCode}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print("Error sending OTP: $e");
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
  Future<void> _checkVerificationInBackground() async {
    print("Starting verification check");
    if (!mounted) {
      print("Widget not mounted, returning");
      return;
    }

    try {
      print("Checking for token");
      final token = await _secureStorage.read(key: 'jwt_token');
      print("Token found: ${token != null}");

      if (token != null) {
        final url = '${APIConstants.baseUrl}/is-verified';
        print("Making verification request to: $url");

        // Prepare the request parameters
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer $token', // Use Authorization header for GET requests
          },
        );

        print("Verification Response Status: ${response.statusCode}");
        print("Verification Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Decoded verification data: $data");

          // Check the verification status and pass user details to the next screen
          if (data['message'] == 'success' && mounted) {
            print("User verified, navigating to RidePage");

            // Pass the user details to the RidePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RidePage(
                  email: data['email'], // Pass email
                  phoneNumber: data['phoneNumber'],
                  isdriver: data['isDriver'] ?? false,
                  documents: data['documents'] ?? false, // Pass phoneNumber
                ),
              ),
            );
            return;
          }
        }
      }
    } catch (e) {
      print("Error during verification: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification check failed: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print("Loading state set to false");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building SignUpScreen. isLoading: $_isLoading");
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: Image.asset('assets/login.png'),
                ),
                const SizedBox(height: 20),
                Text(
                  "LOGIN",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter your email and phone number to get the OTP for verification",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    hintText: 'Enter your email address',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: _isLoading ? Colors.grey.shade200 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    hintText: 'Enter your mobile number',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: _isLoading ? Colors.grey.shade200 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_phoneController.text.length != 10 ||
                              !_emailController.text.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please enter a valid phone number and email.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            sendOtp(_phoneController.text,
                                _emailController.text, context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? Colors.grey
                        : const Color.fromARGB(255, 0, 0, 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 10),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      Text(
                        _isLoading ? 'PLEASE WAIT...' : 'SEND OTP',
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Please wait...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("Disposing SignUpScreen");
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
