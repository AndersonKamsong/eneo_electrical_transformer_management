import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'fault_report_detail.dart';

class FaultReportingScreen extends StatefulWidget {
  @override
  _FaultReportingScreenState createState() => _FaultReportingScreenState();
}

class _FaultReportingScreenState extends State<FaultReportingScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  XFile? _image;

  // Get all fault reports from Firestore
  Stream<List<Map<String, dynamic>>> getFaultReports() {
    return _db.collection('fault_reports').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['reportId'] = doc.id;  // Add reportId field
          return data;
        }).toList());
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('fault_reports/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  // Show modal to create a new fault report
  void _showFaultReportForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report a Fault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Fault Description'),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              TextButton.icon(
                icon: Icon(Icons.photo),
                label: Text('Attach Image'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _image = pickedFile;
                    });
                  }
                },
              ),
              if (_image != null) ...[
                SizedBox(height: 8),
                Image.file(File(_image!.path), height: 100),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _descriptionController.clear();
                setState(() {
                  _image = null;
                });
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_descriptionController.text.isNotEmpty) {
                  String? imageUrl;
                  if (_image != null) {
                    imageUrl = await _uploadImage(File(_image!.path));
                  }

                  // Save the fault report to Firestore
                  await _db.collection('fault_reports').add({
                    'transformer_id': 'transformer123',  // Replace with actual transformer ID
                    'reported_by': 'userId',  // Replace with actual user ID
                    'description': _descriptionController.text,
                    'image_url': imageUrl ?? '',
                    'status': 'Under Review',  // Default status
                  });

                  // Clear fields and close the modal
                  Navigator.pop(context);
                  _descriptionController.clear();
                  setState(() {
                    _image = null;
                  });
                }
              },
              child: Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fault Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showFaultReportForm,
              icon: Icon(Icons.add),
              label: Text('Report a Fault'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getFaultReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No Fault Reports Available.'));
                  }

                  final reports = snapshot.data!;
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      var report = reports[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(report['description']),
                          subtitle: Text('Status: ${report['status']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Handle status update or fault repair progress here
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FaultReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
