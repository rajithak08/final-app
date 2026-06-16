import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Constants.dart';

class JoinedPoolsPage extends StatefulWidget {
  final String userEmail;
  final String userPhone;
  final String? starting;
  final String? destination;
  final List<dynamic>? joinedPools;

  const JoinedPoolsPage({
    Key? key,
    required this.userEmail,
    required this.userPhone,
    this.starting,
    this.destination,
    this.joinedPools,
  }) : super(key: key);

  @override
  _JoinedPoolsPageState createState() => _JoinedPoolsPageState();
}

class _JoinedPoolsPageState extends State<JoinedPoolsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _joinedPools = [];
  List<dynamic> _history = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.joinedPools != null) {
      _joinedPools = widget.joinedPools!;
    } else {
      _fetchJoinedPoolsAndHistory();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchJoinedPoolsAndHistory() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}/user/joined-pools/${widget.userEmail}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _joinedPools = data['joinedPools'] ?? [];
          _history = data['history'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rides: ${e.toString()}')),
      );
    }
  }

  Future<void> _leavePool(String poolId) async {
    try {
      final response = await http.delete(
        Uri.parse('${APIConstants.baseUrl}/leave-pool'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.userEmail,
          'poolId': poolId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _joinedPools.removeWhere((pool) => pool['_id'] == poolId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the ride')),
        );
      } else {
        throw Exception('Failed to leave pool');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving ride: ${e.toString()}')),
      );
    }
  }

Widget _buildRideCard(dynamic ride, bool isHistory) {
  final String? startTimeString = ride['startTime'];

  // Ensure the startTime is not null or empty
  DateTime? rideDate;
  if (startTimeString != null && startTimeString.isNotEmpty) {
    try {
      rideDate = DateTime.parse(startTimeString);
    } catch (e) {
      print('Error parsing date: $e');
    }
  }

  // Format the date properly
  final String formattedDate = rideDate != null
      ? '${rideDate.day}/${rideDate.month}/${rideDate.year} ${rideDate.hour}:${rideDate.minute.toString().padLeft(2, '0')}'
      : 'N/A';

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From: ${ride['pickupLocation'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: ${ride['dropoffLocation'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isHistory)
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  onPressed: () => _showLeaveDialog(ride['_id']),
                ),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow(Icons.person, 'Driver', ride['driver'] ?? 'N/A'),
          _buildDetailRow(Icons.access_time, 'Start Time', ride['startTime']),
           _buildDetailRow(Icons.access_time, 'Start Date', ride['date']),
          _buildDetailRow(
              Icons.attach_money, 'Cost', '₹${ride['cost'] ?? 'N/A'}'),
          if (!isHistory) ...[
            _buildDetailRow(
              Icons.group,
              'Passengers',
              '${ride['passengers']?.length ?? 0}/${(ride['seats_available'] ?? 0) + (ride['passengers']?.length ?? 0)}',
            ),
            _buildDetailRow(
                Icons.phone, 'Driver Contact', ride['driver_phone'] ?? 'N/A'),
            _buildDetailRow(
                Icons.info_outline, 'Status', ride['status'] ?? 'Active'),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaveDialog(String poolId) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Ride'),
        content: const Text('Are you sure you want to leave this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leavePool(poolId);
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> items, bool isHistory) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistory ? Icons.history : Icons.directions_car,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isHistory ? 'No ride history' : 'No active rides',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildRideCard(items[index], isHistory),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Rides',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJoinedPoolsAndHistory,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Active Rides'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_joinedPools, false),
          _buildTabContent(_history, true),
        ],
      ),
    );
  }
}
