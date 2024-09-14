import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  // Getter for the current user
  User? get currentUser => _currentUser;

  // Getter to check if the user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // Register a user with email and password
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Create a new user with Firebase authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _currentUser = userCredential.user;

      // Store additional user data in Firestore (optional fields can be added here)
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'email': email,
        'uid': _currentUser!.uid,
      });

      notifyListeners(); // Notify listeners of state change
      return true; // Return true on successful registration
    } catch (e) {
      print("Error in registration: $e");
      return false; // Return false on error
    }
  }

  // Sign in a user with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in the user with Firebase authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _currentUser = userCredential.user;
      
      notifyListeners(); // Notify listeners of state change
      return true; // Return true on successful login
    } catch (e) {
      print("Error in sign-in: $e");
      return false; // Return false on error
    }
  }

  // Logout the current user
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null; // Reset the current user
    notifyListeners(); // Notify listeners of state change
  }

  // Stream to get all users (this can be filtered to show only online users)
  Stream<List<Map<String, dynamic>>> getOnlineUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
