import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_transformer_screen.dart'; // Screen for adding a transformer
import 'edit_transformer_screen.dart'; // Screen for editing a transformer
import 'transformer_detail_screen.dart'; // Screen for transformer detail
import '../../services/transformer_service.dart';
import '../auth/login_screen.dart'; // Import login screen

class TransformerManagementScreen extends StatefulWidget {
  @override
  _TransformerManagementScreenState createState() => _TransformerManagementScreenState();
}

class _TransformerManagementScreenState extends State<TransformerManagementScreen> {
  final TransformerService _service = TransformerService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      await _fetchUserRole();
    }
  }

  Future<void> _fetchUserRole() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    setState(() {
      _userRole = userDoc['role'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool canManage = _userRole == 'Admin' || _userRole == 'Supervisor';

    return Scaffold(
      appBar: AppBar(title: Text('Transformer Management')),
      floatingActionButton: canManage
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransformerScreen()),
          );
        },
        child: Icon(Icons.add),
      )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.fetchTransformers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transformers = snapshot.data ?? [];
          if (transformers.isEmpty) {
            return Center(child: Text('No transformers available'));
          }

          return ListView.builder(
            itemCount: transformers.length,
            itemBuilder: (context, index) {
              final transformer = transformers[index];
              return Card(
                child: ListTile(
                  title: Text(transformer['location'] ?? 'Unknown Location'),
                  subtitle: Text('Capacity: ${transformer['capacity']} - Status: ${transformer['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransformerDetailsScreen(transformerData: transformer),
                            ),
                          );
                        },
                      ),
                      if (canManage) ...[
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTransformerScreen(transformerData: transformer),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _service.deleteTransformer(transformer['id']);
                            setState(() {});
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
