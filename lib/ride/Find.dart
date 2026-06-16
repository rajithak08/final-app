import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Constants.dart';
import 'package:SS_Pool/ride/JoinedPool.dart';
import 'package:SS_Pool/ride/chat.dart';
import 'package:intl/intl.dart';

class ListOfAvailablePools extends StatefulWidget {
  final List<dynamic> availableRides;
  final String userEmail;
  final String userPhone;
  final String? starting;
  final String? destination;
  ListOfAvailablePools({
    required this.availableRides,
    required this.userEmail,
    required this.userPhone,
    this.starting,
    this.destination,
  });

  @override
  _ListOfAvailablePoolsState createState() => _ListOfAvailablePoolsState();
}

class _ListOfAvailablePoolsState extends State<ListOfAvailablePools> {
  List<dynamic> joinedPools = [];
  List<dynamic> availableRides = [];
  bool _isLoading = false;
  Map<String, bool> joiningStates = {}; // Track joining state for each pool

  @override
  void initState() {
    super.initState();
    availableRides = List.from(widget.availableRides);
    _fetchAvailableRides();
  }

  Future<void> _fetchAvailableRides() async {
    setState(() {
      _isLoading = true;
    });
    print(widget.starting);
    print(widget.destination);
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}/findride'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pickupLocation': widget.starting,
          'dropoffLocation': widget.destination,
          'email': widget.userEmail,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          availableRides = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching available rides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> joinPool(Map<String, dynamic> ride, bool isFullRide) async {
    final poolId = ride['_id'];
    if (joiningStates[poolId] == true) return; // Prevent double-joining

    setState(() {
      joiningStates[poolId] = true;
    });

    try {
      // Join the pool and add the passenger in one request
      final joinPoolResponse = await http.post(
        Uri.parse('${APIConstants.baseUrl}${isFullRide ? "/join-pool/full" : "/join-pool"}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'poolId': poolId,
          'email': widget.userEmail,
          'phoneNumber': widget.userPhone,
          'name': widget.userEmail.split('@')[0],
        }),
      );
      print(joinPoolResponse.body);
      if (joinPoolResponse.statusCode == 200) {
        setState(() {
          joinedPools.add(ride);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined the pool!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinedPoolsPage(
              joinedPools: joinedPools,
              userEmail: widget.userEmail,
              userPhone: widget.userPhone,
              starting: widget.starting,
              destination: widget.destination,
            ),
          ),
        );
      } else {
        final errorData = json.decode(joinPoolResponse.body);
        throw Exception(errorData['message'] ?? 'Failed to join pool');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining pool: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        joiningStates[poolId] = false;
      });
    }
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d, yyyy').format(parsedDate);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Pools',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAvailableRides,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAvailableRides,
        child: _isLoading && availableRides.isEmpty
            ? Center(child: CircularProgressIndicator())
            : availableRides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car,
                            size: 100, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'No available pools found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: availableRides.length,
                    itemBuilder: (context, index) {
                      final ride = availableRides[index];
                      final poolId = ride['_id'];
                      final source = ride['pickupLocation'] ?? 'Unknown Source';
                      final destination =
                          ride['dropoffLocation'] ?? 'Unknown Destination';
                      final startTime = ride['startTime'] ?? 'N/A';
                      final rideDate = ride['date'] ?? 'N/A';
                      final driverPhone = ride['driver_phone'] ?? 'Unknown';
                      final seatsAvailable =
                          ride['seats_available']?.toString() ?? 'N/A';
                      final cost = ride['cost']?.toString() ?? '0';
                      final isJoining = joiningStates[poolId] ?? false;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Route Information
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          source,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Icon(Icons.arrow_downward,
                                            color: Colors.grey),
                                        Text(
                                          destination,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹$cost',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '$seatsAvailable Seats Left',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: seatsAvailable == '0'
                                                ? Colors.red
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Divider(height: 20, color: Colors.grey[300]),

                                // Ride Details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                          _formatDate(rideDate),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                          startTime,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      'Driver: $driverPhone',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.email,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Email: ${ride['driver_email'] ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween, // Adjust alignment as needed
                                  children: [
                                    // Left Button
                                    ElevatedButton(
                                      onPressed:
                                          (int.parse(seatsAvailable) > 0 &&
                                                  !isJoining)
                                              ? () => joinPool(ride, true)
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (int.parse(seatsAvailable) > 0 &&
                                                    !isJoining)
                                                ? Colors.black
                                                : Colors.grey,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: isJoining
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              int.parse(seatsAvailable) > 0
                                                  ? 'Rent Solo'
                                                  : 'Unavailable',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),

                                    // Right Button
                                    ElevatedButton(
                                      onPressed:
                                          (int.parse(seatsAvailable) > 0 &&
                                                  !isJoining)
                                              ? () => joinPool(ride, false)
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (int.parse(seatsAvailable) > 0 &&
                                                    !isJoining)
                                                ? Colors.black
                                                : Colors.grey,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: isJoining
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              int.parse(seatsAvailable) > 0
                                                  ? 'Join Pool'
                                                  : 'Pool Full',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
