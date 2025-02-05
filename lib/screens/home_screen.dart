import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserRole(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
    if (userDoc.exists) {
      return userDoc["role"];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    User? user = authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null)
              FutureBuilder<String?>(
                future: getUserRole(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData) {
                    return Text("Welcome ${user.email}\nRole: ${snapshot.data}");
                  } else {
                    return Text("User role not found");
                  }
                },
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authService.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              },
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
