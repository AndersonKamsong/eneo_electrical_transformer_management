import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a random password
  String _generateRandomPassword(int length) {
    const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*";
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  // Add User (Admin Only)
  Future<User?> addUser({
    required String adminUid,
    required String email,
    required String username,
    required String role,
  }) async {
    try {
      // Check if the admin user is indeed an admin
      DocumentSnapshot adminDoc = await _firestore.collection("users").doc(adminUid).get();
      if (!adminDoc.exists || adminDoc["role"] != "admin") {
        throw PlatformException(code: "permission-denied", message: "Only admins can create new users");
      }

      // Generate random password
      String randomPassword = _generateRandomPassword(8);

      // Create user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: randomPassword,
      );
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "username": username,
          "email": email,
          "role": role,
          "already_verify": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        // Send Email with generated password (Assuming email sending function is implemented)
        await sendEmail(email, "Your Account Details", "Your password is: $randomPassword. Please change it after login.");
      }
      return user;
    } catch (e) {
      print("Add User Error: $e");
      return null;
    }
  }

  // User Login
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();
        if (userDoc.exists && !(userDoc["already_verify"] as bool)) {
          print("User needs to change password on first login");
        }
      }
      return user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  // Update Password & Verify User
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        await _firestore.collection("users").doc(user.uid).update({"already_verify": true});
        print("Password updated and user verified");
      }
    } catch (e) {
      print("Update Password Error: $e");
    }
  }

  // Update User Profile
  Future<void> updateProfile(String uid, {String? username, String? phone, String? address}) async {
    try {
      Map<String, dynamic> updateData = {};
      if (username != null) updateData["username"] = username;
      if (phone != null) updateData["phone"] = phone;
      if (address != null) updateData["address"] = address;

      if (updateData.isNotEmpty) {
        await _firestore.collection("users").doc(uid).update(updateData);
        print("Profile updated successfully");
      }
    } catch (e) {
      print("Update Profile Error: $e");
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fetch User Details
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("User data not found");
        return null;
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // Placeholder for email sending function
  Future<void> sendEmail(String email, String subject, String body) async {
    print("Email sent to $email with subject: $subject");
  }
}
