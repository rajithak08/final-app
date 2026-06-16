import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Constants.dart';

class MyPools extends StatefulWidget {
  final String email;

  const MyPools({Key? key, required this.email}) : super(key: key);

  @override
  _MyPoolsState createState() => _MyPoolsState();
}

class _MyPoolsState extends State<MyPools> {
  List<dynamic> myPools = [];
  bool isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchMyPools();
    // Start long polling
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        fetchMyPools();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchMyPools() async {
    try {
      final response = await http.get(
        Uri.parse('${APIConstants.baseUrl}/mypools/${widget.email}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          myPools = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pools');
      }
    } catch (e) {
      print('Error fetching pools: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _deletePool(String id) async {
    try {
      print('Deleting pool with id: $id'); // Debug log
      final url = '${APIConstants.baseUrl}/pool/$id';
      print('Delete URL: $url'); // Debug log

      final response = await http
          .delete(
            Uri.parse(url),
          )
          .timeout(Duration(seconds: 10)); // Add timeout

      print('Delete response status: ${response.statusCode}'); // Debug log
      print('Delete response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        setState(() {
          myPools.removeWhere((pool) => pool['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pool deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to delete pool: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Delete error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting pool: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _removePassenger(String poolId, String passengerEmail) async {
    try {
      final response = await http.delete(
        Uri.parse('${APIConstants.baseUrl}/remove-passenger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'poolId': poolId,
          'email': passengerEmail,
        }),
      );

      print('Remove passenger response status: ${response.statusCode}');
      print('Remove passenger response body: ${response.body}');

      if (response.statusCode == 200) {
        // Refresh the pools to get the updated data
        await fetchMyPools();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Passenger removed successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(
            'Failed to remove passenger: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Remove passenger error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing passenger: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'My Pools',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isLoading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchMyPools,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            )
          : myPools.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pools found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: myPools.length,
                  itemBuilder: (context, index) {
                    final pool = myPools[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            '${pool['pickupLocation'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            '${pool['dropoffLocation'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${pool['cost'] ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${pool['seats_available'] ?? 0} seats left',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 18, color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Time: ${pool['startTime'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 15,
                                      ),
                                    ),
                                
                                  ],
                                ),

                                     Row(
                                  children: [
                                    Icon(Icons.date_range,
                                        size: 18, color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Date: ${pool['date'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 15,
                                      ),
                                    ),
                                
                                  ],
                                ),
                                if (pool['driver_phone'] != null) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 18, color: Colors.grey[700]),
                                      SizedBox(width: 8),
                                      Text(
                                        'Driver: ${pool['driver_phone']}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if ((pool['passengers'] as List?)?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 16),
                                  Text(
                                    'Passengers',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        ...((pool['passengers'] as List?) ?? [])
                                            .map((passenger) => Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey
                                                            .withOpacity(0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.05),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                            Icons.person,
                                                            size: 20,
                                                            color:
                                                                Colors.black54),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              '${passenger['phoneNumber'] ?? 'N/A'}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              '${passenger['email'] ?? 'N/A'}',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                            Icons.remove_circle,
                                                            color: Colors.red),
                                                        onPressed: () =>
                                                            _removePassenger(
                                                                pool["_id"],
                                                                passenger[
                                                                    'email']),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _deletePool(pool["_id"]),
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      label: Text(
                                        'Delete Pool',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
