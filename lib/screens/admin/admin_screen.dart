import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_users.dart';  // Replace with your user management screen
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Management Section
            _buildSectionTitle("User Management"),
            _buildListItem(
              context,
              title: "Manage Users",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                );
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  // Builds a section header
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Creates a clickable list item for each action
  Widget _buildListItem(BuildContext context, {required String title, required void Function() onTap}) {
    return ListTile(
      title: Text(title),
      onTap: onTap,
    );
  }

}
