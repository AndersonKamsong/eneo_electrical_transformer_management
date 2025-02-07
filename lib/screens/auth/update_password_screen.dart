import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Import your AuthService class

class UpdatePasswordPage extends StatefulWidget {
  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      String newPassword = _newPasswordController.text;
      await _authService.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );
      Navigator.pop(context); // Go back to the profile page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePassword,
                child: Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}