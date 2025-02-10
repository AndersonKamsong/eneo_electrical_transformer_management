import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For formatting date
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

  // Query transformer and user data for display
  Future<Map<String, dynamic>> _getTransformerData(String transformerId) async {
    var transformerSnapshot = await _db.collection('transformers').doc(transformerId).get();
    print("transformerSnapshot.data()");
    print(transformerSnapshot.data());
    return transformerSnapshot.data() ?? {};
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    var userSnapshot = await _db.collection('users').doc(userId).get();
    print("userSnapshot.data()");
    print(userSnapshot.data());
    return userSnapshot.data() ?? {};
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fault Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                      String transformerId = report['transformer_id'];
                      String userId = report['reported_by'];

                      return FutureBuilder<Map<String, dynamic>>(
                        future: Future.wait([
                          _getTransformerData(transformerId),
                          _getUserData(userId)
                        ]).then((results) {
                          var transformerData = results[0];
                          var userData = results[1];
                          return {
                            'transformer': transformerData,
                            'user': userData,
                          };
                        }),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!futureSnapshot.hasData) {
                            return Card(child: ListTile(title: Text('Error loading data')));
                          }

                          var data = futureSnapshot.data!;
                          var transformer = data['transformer'];
                          var user = data['user'];

                          // Format date
                          var formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(
                            (report['date'] as Timestamp).toDate(),
                          );

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(report['description']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${report['status']}'),
                                  Text('Zone: ${report['zone']}'),
                                  Text('Reported by: ${user['name'] ?? 'Unknown User'}'),
                                  Text('Transformer No ${transformer['id'] ?? 'Unknown Transformer'} at ${transformer['location'] ?? 'Unknown location'}'),
                                  Text('Date: $formattedDate'),
                                ],
                              ),
                              trailing: report['image_url'] != null && report['image_url']!.isNotEmpty
                                  ? Image.network(report['image_url'], width: 50, height: 50)
                                  : null,
                            ),
                          );
                        },
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
