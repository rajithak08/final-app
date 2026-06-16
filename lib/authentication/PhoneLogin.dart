import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:SS_Pool/authentication/OTPVerification.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:SS_Pool/authentication/UserProvider.dart';
import 'package:provider/provider.dart';



class LoginScreen extends StatelessWidget {
  final TextEditingController _phoneController = TextEditingController();

  Future<void> fetchUserByPhone(
      String phoneNumber, UserProvider userProvider, BuildContext context) async {
    final url =
        'http://your-server-address/users/phone/$phoneNumber'; // Update with your server address
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      userProvider.setUser(user['userId'], user['phoneNumber'], user['email']);
      Navigator.pushNamed(context, '/home'); // Navigate to the home screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not found! Please sign up first.',
              style: TextStyle(color: Colors.red)),
          backgroundColor: Colors.grey.shade100,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenSize.height * 0.12), // Adjusts based on screen

                // Illustration
                Container(
                  height: screenSize.height * 0.25,
                  child: Image.asset('assets/login.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),

                // App Name
                Text(
                  "LOGIN",
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                // Info Text
                Text(
                  "Enter your phone number to login",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Mobile Number Input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 15,
                      horizontal: 10,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final phoneNumber = _phoneController.text;

                      // Validate phone number length
                      if (phoneNumber.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid 10-digit phone number.',
                                style: TextStyle(color: Colors.red)),
                            backgroundColor: Colors.grey.shade100,
                          ),
                        );
                      } else {
                        await fetchUserByPhone(phoneNumber, userProvider, context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'LOGIN',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.05),
              ],
            ),
          );
        },
      ),
    );
  }
}



void main() => runApp(MaterialApp(home: LoginScreen()));
