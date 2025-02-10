import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransformerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transformerData;

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
                onPressed: () => _showMaintenanceTaskForm(context),
                child: Text('Create Maintenance Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
