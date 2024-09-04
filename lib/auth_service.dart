import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final Map<String, String> _registeredUsers = {};
  String? _currentUser;

  String? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool registerWithEmailAndPassword(String email, String password) {
    if (_registeredUsers.containsKey(email)) {
      return false; 
    }
    _registeredUsers[email] = password;
    notifyListeners();
    return true;
  }

  bool signInWithEmailAndPassword(String email, String password) {
    if (_registeredUsers[email] == password) {
      _currentUser = email;
      notifyListeners();
      return true;
    }
    return false; 
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  List<String> getOnlineUsers() {
    return _registeredUsers.keys.toList(); 
  }
}
