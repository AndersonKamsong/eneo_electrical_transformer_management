import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/maintenance_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  TaskDetailScreen({required this.taskId});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  String assignedTo = '';
  String status = 'pending';

  // Load task details
  Future<Map<String, dynamic>> loadTaskDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('maintenance_tasks').doc(widget.taskId).get();
    return doc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadTaskDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var task = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transformer ID: ${task['transformer_id']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Scheduled Date: ${task['scheduled_date']}'),
                Text('Current Status: ${task['status']}'),

                DropdownButton<String>(
                  value: status,
                  items: ['pending', 'completed', 'overdue']
                      .map((status) => DropdownMenuItem(value: status, child: Text(status.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      status = value!;
                    });
                    _maintenanceService.updateTaskStatus(widget.taskId, status);
                  },
                ),

                SizedBox(height: 20),
                Text('Assign Task to a Technician:'),
                TextField(
                  onChanged: (value) {
                    assignedTo = value;
                  },
                  decoration: InputDecoration(labelText: 'Enter Technician ID'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (assignedTo.isNotEmpty) {
                      _maintenanceService.assignTask(widget.taskId, assignedTo);
                    }
                  },
                  child: Text('Assign'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
