import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddUserDialog();
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditUserDialog(user: user);
      },
    );
  }

  void _toggleUserBlock(String userId, bool isBlocked) async {
    print("userId");
    print(userId);
    String adminUid =  FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot adminDoc = await _firestore.collection("users").doc(adminUid).get();
    if (!adminDoc.exists || adminDoc["role"] != "Admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('permission-denied: Only admins can block user')),
      );
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'blocked': !isBlocked});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User blocked successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users available.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isBlocked = user['blocked'] ?? false;
              return Card(
                elevation: 5,
                child: ListTile(
                  title: Text(user["username"] ?? "Unknown"),
                  subtitle: Text(user["role"] ?? "No Role"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditUserDialog(user),
                      ),
                      IconButton(
                        icon: Icon(
                          isBlocked ? Icons.lock : Icons.lock_open,
                          color: isBlocked ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleUserBlock(user['uid'], isBlocked),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  @override
  _AddUserDialogState createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _role = 'Admin';
  bool _isLoading = false;

  final List<String> roles = ['Admin', 'Technician', 'Supervisor'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          DropdownButton<String>(
            value: _role,
            items: roles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _role = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
            final email = _emailController.text;
            final username = _usernameController.text;
            if (email.isNotEmpty && username.isNotEmpty) {
              setState(() {
                _isLoading = true;
              });
              try {
                User? newUser = await AuthService().addUser(
                  adminUid: FirebaseAuth.instance.currentUser!.uid,
                  email: email,
                  username: username,
                  role: _role,
                );

                if (newUser != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User $username added successfully!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error adding user')),
                  );
                }
              } catch (e) {
                print('Error adding user: $e');
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Add User'),
        ),
      ],
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserDialog({required this.user, super.key});

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late String _role;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> roles = ['Admin', 'Technician', 'Supervisor'];

  @override
  void initState() {
    super.initState();
    _role = widget.user['role'] ?? 'Technician';
  }

  void _updateUserRole() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String adminUid =  FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot adminDoc = await _firestore.collection("users").doc(adminUid).get();
      if (!adminDoc.exists || adminDoc["role"] != "Admin") {
        throw PlatformException(code: "permission-denied", message: "Only admins can edit user role");
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user['uid'])
          .update({'role': _role});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user role: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _role,
            items: roles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _role = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _updateUserRole,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Update'),
        ),
      ],
    );
  }
}