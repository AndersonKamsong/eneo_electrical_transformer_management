import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart'; // Import login screen

class TransformerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transformerData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final String? _userRole;

  const TransformerDetailsScreen({Key? key, required this.transformerData}) : super(key: key);

  // Function to open Google Maps with the transformer location
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  Future<void> _createFaultReport(BuildContext context, String description, File? image) async {
    try {
      CollectionReference faultReports = FirebaseFirestore.instance.collection(
          'fault_reports');

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String connectedUserId = user?.uid ?? 'Unknown User';

        DocumentReference reportRef = await faultReports.add({
          'transformer_id': transformerData['id'],
          'reported_by': connectedUserId,
          'description': description,
          'zone': transformerData['zone'],
          'date': Timestamp.now(),
          'image_url': null, // Placeholder for image URL
        });

        // // If an image is selected, upload it to Firebase Storage
        // if (image != null) {
        //   Reference storageRef = FirebaseStorage.instance
        //       .ref()
        //       .child('fault_reports/${reportRef.id}.jpg');
        //
        //   await storageRef.putFile(image);
        //   String imageUrl = await storageRef.getDownloadURL();
        //
        //   // Update the fault report with the image URL
        //   await reportRef.update({'image_url': imageUrl});
        // }

        // Update the transformer status to "Faulty"
        await FirebaseFirestore.instance.collection('transformers').doc(
            transformerData['id']).update({
          'status': 'Faulty',
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fault Report Created Successfully!')));
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login First')));
      }

      } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating report: $e')));
    }
  }

  // Function to create a new maintenance task
  Future<void> _createMaintenanceTask(BuildContext context, String taskName, String technicianId, DateTime scheduledDate, String zone) async {
    try {
      CollectionReference maintenanceTasks = FirebaseFirestore.instance.collection('maintenance_tasks');

      await maintenanceTasks.add({
        'transformer_id': transformerData['id'], // Assuming the transformer has an 'id' field
        'assigned_to': technicianId,
        'status': 'Pending',
        'scheduled_date': Timestamp.fromDate(scheduledDate),
        'zone': zone,  // Save the zone
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maintenance Task Created Successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating task: $e')));
    }
  }

  void _showFaultReportForm(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report Transformer Fault'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      selectedImage = File(pickedFile.path);
                    }
                  },
                  child: Text('Attach Image (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (descriptionController.text.isNotEmpty) {
                  _createFaultReport(context, descriptionController.text, selectedImage);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a description')));
                }
              },
              child: Text('Report Fault'),
            ),
          ],
        );
      },
    );
  }

  // Form to create a new maintenance task
  void _showMaintenanceTaskForm(BuildContext context) {
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController technicianIdController = TextEditingController();
    DateTime? selectedDate;
    String? selectedZone = transformerData['zone'];  // Pre-select zone from transformer data

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Maintenance Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: taskNameController,
                  decoration: InputDecoration(labelText: 'Task Name'),
                ),
                TextField(
                  controller: technicianIdController,
                  decoration: InputDecoration(labelText: 'Technician ID'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      selectedDate = pickedDate;
                    }
                  },
                  child: Text(selectedDate == null
                      ? 'Select Scheduled Date'
                      : 'Scheduled Date: ${DateFormat.yMMMd().format(selectedDate!)}'),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedZone,
                  items: [
                    'Central', 'Littoral', 'West', 'North', 'South', 'Northwest',
                    'Southwest', 'East', 'Adamawa', 'Far North'
                  ].map((zone) {
                    return DropdownMenuItem(value: zone, child: Text(zone));
                  }).toList(),
                  onChanged: (value) => selectedZone = value,
                  decoration: InputDecoration(labelText: 'Select Zone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (taskNameController.text.isNotEmpty &&
                    technicianIdController.text.isNotEmpty &&
                    selectedDate != null &&
                    selectedZone != null) {
                  _createMaintenanceTask(
                    context,
                    taskNameController.text,
                    technicianIdController.text,
                    selectedDate!,
                    selectedZone!,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
                }
              },
              child: Text('Create Task'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transformer Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity: ${transformerData['capacity']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Location: ${transformerData['location']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Latitude: ${transformerData['latitude']}', style: TextStyle(fontSize: 16)),
            Text('Longitude: ${transformerData['longitude']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Status: ${transformerData['status']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text(
              'Installation Date: ${DateFormat.yMMMd().format((transformerData['installationDate'] as Timestamp).toDate())}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Zone: ${transformerData['zone']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),  // Display zone
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(transformerData['latitude'], transformerData['longitude']),
                icon: Icon(Icons.map),
                label: Text('Open in Google Maps'),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _showFaultReportForm(context),
                child: Text('Report Fault'),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<User?>(
              stream: AuthService().user,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (roleSnapshot.hasError) {
                        return const Center(child: Text('Error loading role'));
                      }

                      final userRole = roleSnapshot.data!['role'] ?? 'user';

                      if (userRole == 'Admin'|| userRole == 'Supervisor') {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () => _showMaintenanceTaskForm(context),
                            child: Text('Create Maintenance Task'),
                          ),
                        );
                      } else {
                        return SizedBox.shrink();  // No icon for regular users
                      }
                    },
                  );
                } else {
                  return SizedBox.shrink();  // No logout button for unauthenticated users
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
