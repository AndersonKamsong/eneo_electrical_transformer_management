import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'maintenance_task_detail_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  @override
  _MaintenanceListScreenState createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? selectedStatus = 'all';

  // Get tasks based on filter
  Stream<List<Map<String, dynamic>>> getTasks(String? status) {
    Query query = _db.collection('maintenance_tasks');

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          // Include the document ID as taskID in the data
          var data = doc.data() as Map<String, dynamic>;
          data['taskId'] = doc.id;  // Add the taskID field
          return data;
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scheduled Maintenance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedStatus,
                  items: ['all', 'pending', 'completed', 'overdue']
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTasks(selectedStatus),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return ListTile(
                      title: Text('Transformer ID: ${task['transformer_id']}'),
                      subtitle: Text('Scheduled Date: ${task['scheduled_date']}'),
                      // subtitle: Text('Scheduled taskId: ${task['taskId']}'),
                      trailing: Text(task['status'].toUpperCase()),
                      onTap: () {
                        // Navigate to Task Detail Screen to assign/review status
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(taskId: task['taskId']),
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
    );
  }
}
