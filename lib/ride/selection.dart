import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:SS_Pool/authentication/OTPVerification.dart';
import 'package:flutter/material.dart';
import 'package:SS_Pool/authentication/PhoneNumber.dart';
import 'package:SS_Pool/ride/Find.dart';
import 'package:http/http.dart' as http;
import 'package:SS_Pool/ride/myPools.dart';
import 'package:uuid/uuid.dart';
import 'package:SS_Pool/authentication/Terms.dart';
import '../Constants.dart';
import 'dart:io';
import 'package:SS_Pool/ride/JoinedPool.dart';
import 'package:SS_Pool/map/google_map_view.dart';

class RidePage extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final bool isdriver;
  final bool documents;
  RidePage(
      {required this.email,
      required this.phoneNumber,
      required this.isdriver,
      required this.documents});

  @override
  _RidePageState createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  String? _selectedSource;
  String? _selectedDestination;
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  List<dynamic> _joinedPools = [];

  final List<String> _sourcelocation = [
    'IIITS',
    'Tada',
    'Sullurupeta',
    'Gummidipoondi',
    'Tirupati',
    'Chennai',
    'Arambakkam'
  ];
  final List<String> _destinationlocation = [
    'IIITS',
    'Tada',
    'Sullurupeta',
    'Gummidipoondi',
    'Tirupati',
    'Chennai',
    'Arambakkam'
  ];

  final List<String> _hours =
      List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _minutes =
      List.generate(60, (index) => index.toString().padLeft(2, '0'));
  final List<String> _amPmOptions = ['AM', 'PM'];
  String? _selectedHour;
  String? _selectedMinute;
  String? _selectedAmPm;

  @override
  void initState() {
    super.initState();
    _selectedSource = null;
    _selectedDestination = null;
    // Set initial state based on user type
    isFindRide = !widget.isdriver; // Non-drivers start with Find Ride
    isOfferRide = false;
    _fetchJoinedPools();
  }

  // New method to fetch joined pools
  Future<void> _fetchJoinedPools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${APIConstants.baseUrl}/user/joined-pools/${widget.email}'),
      );

      print('Joined pools response status: ${response.statusCode}');
      print('Joined pools response body: ${response.body}');

      if (response.statusCode == 200) {
        // Safely parse the JSON response
        dynamic jsonResponse = json.decode(response.body);

        // Ensure _joinedPools is always a list
        setState(() {
          _joinedPools = jsonResponse is List ? jsonResponse : [];
          _isLoading = false;
        });
      } else {
        print('Failed to fetch joined pools: ${response.body}');
        setState(() {
          _joinedPools = []; // Reset to empty list on error
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching joined pools: $e');
      setState(() {
        _joinedPools = []; // Reset to empty list on error
        _isLoading = false;
      });
    }
  }

  bool isFindRide = false;
  bool isOfferRide = false;

  // Helper function to make HTTP/HTTPS requests
  Future<Map<String, dynamic>> makeRequest(
      String endpoint, dynamic body) async {
    print('makeRequest: $endpoint: $body');
    try {
      if (APIConstants.baseUrl.startsWith('https')) {
        // For HTTPS
        final client = HttpClient()
          ..badCertificateCallback =
              ((X509Certificate cert, String host, int port) => true);
        final request =
            await client.postUrl(Uri.parse('${APIConstants.baseUrl}$endpoint'));
        request.headers.set('content-type', 'application/json');
        request.write(json.encode(body));
        final response = await request.close();
        print('Response status: ${response.statusCode}');
        final responseBody = await response.transform(utf8.decoder).join();
        print('Response body: $responseBody');
        return {
          'statusCode': response.statusCode,
          'body': responseBody,
        };
      } else {
        // For HTTP
        final response = await http.post(
          Uri.parse('${APIConstants.baseUrl}$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'statusCode': 500,
        'body': json.encode({'message': 'Network error: ${e.toString()}'})
      };
    }
  }

  // New method to check if user has a ride within 30 minutes
  bool _hasRideWithin30Minutes(String? starting, String? destination) {
    final now = DateTime.now();
    for (var pool in _joinedPools) {
      try {
        // Parse the date and time from the pool
        final dateTimeString = '${pool['date']} ${pool['startTime']}';
        final poolDateTime = _parsePoolDateTime(dateTimeString);
        // Check if the ride is within 30 minutes of its start time
        final timeDifference = poolDateTime.difference(now);
        if (timeDifference.inMinutes.abs() <= 30 &&
            pool['starting'] == starting &&
            pool['destination'] == destination) {
          return false;
        }
      } catch (e) {
        print('Error parsing pool date/time: $e');
      }
    }
    return false;
  }

  // Helper method to parse date and time string
  DateTime _parsePoolDateTime(String dateTimeString) {
    // Expected format: 'YYYY-MM-DD HH:mm AM/PM'
    final parts = dateTimeString.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    final amPm = parts[2];

    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Convert to 24-hour format
    if (amPm == 'PM' && hour != 12) {
      hour += 12;
    } else if (amPm == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      hour,
      minute,
    );
  }

  void _showLogoutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Account Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

         

              Divider(),

              // Logout Option
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Log Out"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
void _switchAccount(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      TextEditingController emailController = TextEditingController();
      return AlertDialog(
        title: Text("Switch Account"),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Enter new email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newEmail = emailController.text.trim();
              if (newEmail.isNotEmpty) {
                try {
                  final url = '${APIConstants.baseUrl}/emails/$newEmail'; // Assuming the endpoint to check email exists
                  final response = await http.get(Uri.parse(url));

                  if (response.statusCode == 200) {
                    // Email exists, continue with your logic
                    print("Email found: $newEmail");
                    Navigator.pop(context);
                  } else if (response.statusCode == 404) {
                    // Email does not exist, show error message
                    showErrorDialog(context, "No account found with this email. Please create a new account.");
                  } else {
                    // Handle other unexpected status codes
                    showErrorDialog(context, "An error occurred. Please try again.");
                  }
                } catch (e) {
                  // Handle network or other errors
                  showErrorDialog(context, "An error occurred. Please check your connection and try again.");
                }
              }
            },
            child: Text("Switch"),
          ),
        ],
      );
    },
  );
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}


  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text(
              "Are you sure you want to log out? This will remove your account from the app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Delete the token from secure storage
                await secureStorage.delete(key: 'jwt_token');
                print("User logged out and account deleted.");

                // Close the dialog
                Navigator.pop(context);

                // Navigate to SignUpScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(),
                  ),
                );
              },
              child: Text("Log Out", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ride Page"),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.exit_to_app),
          //   onPressed: () => _showLogoutModal(context),
          // ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map View
          GoogleMapView(
            sourceLocation: _selectedSource,
            destinationLocation: _selectedDestination,
          ),

          // Menu and Search Buttons (Top-Left and Top-Right)
          Positioned(
            top: 40,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  print(_selectedSource);
                  print(_selectedDestination);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JoinedPoolsPage(
                        joinedPools: _joinedPools,
                        userEmail: widget.email,
                        userPhone: widget.phoneNumber,
                        starting: _selectedSource?.isEmpty ?? true
                            ? null
                            : _selectedSource,
                        destination: _selectedDestination?.isEmpty ?? true
                            ? null
                            : _selectedDestination,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: widget.isdriver
                ? CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.search, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyPools(
                                    email: widget.email,
                                  )),
                        );
                      },
                    ),
                  )
                : SizedBox(), // Empty widget if not a driver
          ),

          // Ride Information Section (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    spreadRadius: 5.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Find Ride and Offer Ride Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isFindRide = true;
                            isOfferRide = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFindRide ? Colors.black : Colors.grey[300],
                          foregroundColor:
                              isFindRide ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        child: Text('Find Ride'),
                      ),
                      if (widget
                          .documents) // Show Offer Ride if driver or if user has documents
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isOfferRide = true;
                              isFindRide = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isOfferRide ? Colors.black : Colors.grey[300],
                            foregroundColor:
                                isOfferRide ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text('Offer Ride'),
                        ),
                      if (!widget
                          .documents) // Show Upload Documents if user doesn't have documents
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TermsAndConditionsPage(
                                  email: widget.email,
                                  phoneNumber: widget.phoneNumber,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isOfferRide ? Colors.black : Colors.grey[300],
                            foregroundColor:
                                isOfferRide ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text('Offer Ride'),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.0),

                  // THIS IS TO FIND THE RIDE

                  // Fields for Find Ride
                  if (isFindRide) ...[
                    _buildDropdownField(
                      hint: 'Select Source',
                      value: _selectedSource,
                      items: _sourcelocation,
                      onChanged: (value) {
                        setState(() {
                          _selectedSource = value;
                        });
                      },
                      icon: Icons.location_on,
                    ),
                    SizedBox(height: 10.0),
                    _buildDropdownField(
                      hint: 'Select Destination',
                      value: _selectedDestination,
                      items: _destinationlocation,
                      onChanged: (value) {
                        setState(() {
                          _selectedDestination = value;
                        });
                      },
                      icon: Icons.location_on_outlined,
                    ),
                    // Add the Join button here
                    SizedBox(height: 20.0),

                     Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),

                             child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.calendar_today, color: Colors.black),
                            hintText: 'Select Date',
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 30)),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          readOnly: true,
                        ),
                      ),
                     ),

                         SizedBox(height: 10.0),


                          Row(
                      children: [
                        // Hours Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedHour,
                                hint: Text('Hour'),
                                isExpanded: true,
                                underline: Container(),
                                items: _hours.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedHour = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),

                        // Minutes Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedMinute,
                                hint: Text('Minute'),
                                isExpanded: true,
                                underline: Container(),
                                items: _minutes.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedMinute = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),

                        // AM/PM Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedAmPm,
                                hint: Text('AM/PM'),
                                isExpanded: true,
                                underline: Container(),
                                items: _amPmOptions
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedAmPm = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),

                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_selectedSource == null ||
                                  _selectedDestination == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please select both source and destination')),
                                );
                                return;
                              }

                              if (_selectedSource == _selectedDestination) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Source and destination cannot be the same')),
                                );
                                return;
                              }

                              if (_hasRideWithin30Minutes(
                                  _selectedSource, _selectedDestination)) {
                                // Find the specific ride within 30 minutes
                                var nearbyRide = _joinedPools.firstWhere(
                                  (pool) {
                                    final dateTimeString =
                                        '${pool['date']} ${pool['startTime']}';
                                    final poolDateTime =
                                        _parsePoolDateTime(dateTimeString);
                                    final timeDifference =
                                        poolDateTime.difference(DateTime.now());
                                    return timeDifference.inMinutes.abs() <= 30;
                                  },
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'You have an existing ride at ${nearbyRide['startTime']} on ${nearbyRide['date']}. You cannot book a new ride within 30 minutes of an existing ride.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);
                              try {
                                final requestBody = {
                                  'pickupLocation': _selectedSource,
                                  'dropoffLocation': _selectedDestination,
                                  'email': widget.email,
                                };

                                final response =
                                    await makeRequest('/findride', requestBody);

                                if (response['statusCode'] == 200) {
                                  final rides = json.decode(response['body']);
                                  if (rides is List && rides.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'No rides available for this route')),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ListOfAvailablePools(
                                        availableRides: rides,
                                        userEmail: widget.email,
                                        userPhone: widget.phoneNumber,
                                        starting: _selectedSource,
                                        destination: _selectedDestination,
                                      ),
                                    ),
                                  );
                                } else {
                                  var errorMessage = 'Failed to find rides';
                                  try {
                                    final errorBody =
                                        json.decode(response['body']);
                                    errorMessage =
                                        errorBody['message'] ?? errorMessage;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Network error: Please check your connection')),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('SEARCH'),
                    ),
                  ],

                  // Fields for Offer Ride
                  if (isOfferRide && widget.documents) ...[
                    _buildDropdownField(
                      hint: 'Select Source',
                      value: _selectedSource,
                      items: _sourcelocation,
                      onChanged: (value) {
                        setState(() {
                          _selectedSource = value;
                        });
                      },
                      icon: Icons.location_on,
                    ),
                    SizedBox(height: 10.0),
                    _buildDropdownField(
                      hint: 'Select Destination',
                      value: _selectedDestination,
                      items: _destinationlocation,
                      onChanged: (value) {
                        setState(() {
                          _selectedDestination = value;
                        });
                      },
                      icon: Icons.location_on_outlined,
                    ),
                    SizedBox(height: 10.0),

                    // Date picker
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.calendar_today, color: Colors.black),
                            hintText: 'Select Date',
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 30)),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          readOnly: true,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),

                    // Time Dropdowns
                    Row(
                      children: [
                        // Hours Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedHour,
                                hint: Text('Hour'),
                                isExpanded: true,
                                underline: Container(),
                                items: _hours.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedHour = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),

                        // Minutes Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedMinute,
                                hint: Text('Minute'),
                                isExpanded: true,
                                underline: Container(),
                                items: _minutes.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedMinute = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),

                        // AM/PM Dropdown
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: DropdownButton<String>(
                                value: _selectedAmPm,
                                hint: Text('AM/PM'),
                                isExpanded: true,
                                underline: Container(),
                                items: _amPmOptions
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedAmPm = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextFormField(
                          controller: _seatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.event_seat, color: Colors.black),
                            hintText: 'Enter Number of Seats',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextFormField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.currency_rupee, color: Colors.black),
                            hintText: 'Enter Cost Per Person',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    // Add the Join button here
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              // Validate all required fields
                              if (_selectedSource == null ||
                                  _selectedDestination == null ||
                                  _dateController.text.isEmpty ||
                                  _selectedHour == null ||
                                  _selectedMinute == null ||
                                  _selectedAmPm == null ||
                                  _seatsController.text.isEmpty ||
                                  _costController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Please fill in all fields')),
                                );
                                return;
                              }

                              if (_selectedSource == _selectedDestination) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Source and destination cannot be the same')),
                                );
                                return;
                              }

                              // Validate seats
                              final seats = int.tryParse(_seatsController.text);
                              if (seats == null || seats <= 0 || seats > 20) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please enter a valid number of seats (1-20)')),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);
                              try {
                                final requestBody = {
                                  'pickupLocation': _selectedSource,
                                  'dropoffLocation': _selectedDestination,
                                  'date': _dateController.text,
                                  'startTime':
                                      '$_selectedHour:$_selectedMinute $_selectedAmPm',
                                  'cost': int.parse(_costController.text),
                                  'seats_available':
                                      int.parse(_seatsController.text),
                                  'driver_phone': widget.phoneNumber,
                                  'driver_email': widget.email,
                                };

                                final response =
                                    await makeRequest('/rides', requestBody);

                                if (response['statusCode'] == 201) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Car pool created successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Clear all fields after successful creation
                                  setState(() {
                                    _selectedSource = null;
                                    _selectedDestination = null;
                                    _dateController.clear();
                                    _selectedHour = null;
                                    _selectedMinute = null;
                                    _selectedAmPm = null;
                                    _seatsController.clear();
                                    _costController.clear();
                                  });
                                  // Navigate to MyPools page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MyPools(email: widget.email),
                                    ),
                                  );
                                } else {
                                  var errorMessage =
                                      'Failed to create car pool';
                                  try {
                                    final errorBody =
                                        json.decode(response['body']);
                                    errorMessage =
                                        errorBody['message'] ?? errorMessage;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Network error: Please check your connection'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Offer Ride'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    // Filter out the selected value from the other dropdown to prevent same selection
    List<String> availableItems = items.where((item) {
      if (hint.contains('Source')) {
        return item != _selectedDestination;
      } else {
        return item != _selectedSource;
      }
    }).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: Container(), // Remove the default underline
        items: availableItems.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            // Clear the other dropdown if it has the same value
            if (hint.contains('Source') && newValue == _selectedDestination) {
              setState(() => _selectedDestination = null);
            } else if (hint.contains('Destination') &&
                newValue == _selectedSource) {
              setState(() => _selectedSource = null);
            }
            onChanged(newValue);
          }
        },
      ),
    );
  }

  void _logOut(BuildContext context) async {
    // Delete the token from secure storage
    await secureStorage.delete(key: 'jwt_token');

    // Navigate to SignUpPage with email and phone number
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SignUpScreen(),
      ),
    );
  }
}
