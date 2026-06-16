import 'package:flutter/material.dart';
import 'package:SS_Pool/Constants.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _phoneNumber;
  String? _email;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;

  void setUser(String userId, String phoneNumber , String email) {
    _userId = userId;
    _phoneNumber = phoneNumber;
    _email = email;
    Constants.userId = userId; // Update Constants
    notifyListeners(); // Notify listeners when data is updated
  }
}
