import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Constants.dart'; // Import your constants file
import 'package:SS_Pool/ride/selection.dart';

class TermsAndConditionsPage extends StatefulWidget {
  final String email;
  final String phoneNumber;

  const TermsAndConditionsPage(
      {Key? key, required this.email, required this.phoneNumber})
      : super(key: key);

  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  String? aadhaarFileName;
  String? licenseFileName;
  bool isAgreed = false;
  bool _isLoading = false;

  Future<void> pickFile(Function(String) onFilePicked) async {
    try {
      // Allow image files (png, jpg, jpeg)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // This will allow only image files
      );
      if (result != null) {
        // Get the absolute path of the selected file
        String? filePath = result.files.single.path;

        if (filePath != null) {
          onFilePicked(filePath);
        } else {
          throw Exception("Failed to get the file path.");
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to pick file: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> uploadFiles() async {
    print('Aadhaar File Path: $aadhaarFileName');
    print('License File Path: $licenseFileName');

    if (aadhaarFileName == null || licenseFileName == null || !isAgreed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content:
              const Text('Please upload all files and agree to the terms.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final url = Uri.parse('${APIConstants.baseUrl}/license');

      var request = http.MultipartRequest('POST', url);
      request.fields['email'] = widget.email;

      // Attach files
      if (aadhaarFileName != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'aadhaar',
          aadhaarFileName!,
        ));
      }
      if (licenseFileName != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'license',
          licenseFileName!,
        ));
      }

      var response = await request.send();
      debugPrint('Response: $response', wrapWidth: 1024);
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = jsonDecode(responseBody);

        var email = data['data']['email'];
        var phone = data['data']['phone'];
        var isdriver = data['data']['isDriver'];
        // Show success dialog and redirect
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Files uploaded successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.pop(context);
                  // Redirect to RidePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RidePage(
                            email: email,
                            phoneNumber: phone,
                            isdriver: isdriver,
                            documents: true
                          )),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(
            'Failed to upload files. Status code: ${response.statusCode}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/aadhar.png', // Replace with your image path
                  height: 200,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upload Aadhaar Card',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => pickFile((fileName) {
                  setState(() {
                    aadhaarFileName = fileName;
                  });
                }),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      aadhaarFileName ?? 'Tap to upload Aadhaar Card',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Driver\'s License',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => pickFile((fileName) {
                  setState(() {
                    licenseFileName = fileName;
                  });
                }),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      licenseFileName ?? 'Tap to upload Driver\'s License',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: isAgreed,
                    onChanged: (value) {
                      setState(() {
                        isAgreed = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Terms and Conditions',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  uploadFiles();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Agree',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 