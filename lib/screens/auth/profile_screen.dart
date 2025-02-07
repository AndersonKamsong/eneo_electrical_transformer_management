import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Import your AuthService class
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      Map<String, dynamic>? details = await _authService.getUserDetails(user.uid);
      setState(() {
        _userDetails = details;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: _userDetails == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${_userDetails!['username']}'),
            Text('Email: ${_userDetails!['email']}'),
            Text('Role: ${_userDetails!['role']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/updatePassword');
              },
              child: Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}