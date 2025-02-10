import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FaultReportScreen extends StatelessWidget {
  // Method to update status in Firestore
  Future<void> updateStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('fault_reports')
          .doc(reportId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  // Method to update progress in Firestore
  Future<void> updateProgress(String reportId, double progress) async {
    try {
      await FirebaseFirestore.instance
          .collection('fault_reports')
          .doc(reportId)
          .update({'progress': progress});
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  // Stream to get fault reports
  Stream<List<Map<String, dynamic>>> getFaultReports() {
    return FirebaseFirestore.instance
        .collection('fault_reports')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fault Reports')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getFaultReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final reportId = report['reportId'];
              final status = report['status'];
              final progress = report['progress'] ?? 0.0;

              return ListTile(
                title: Text('Fault: ${report['description']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $status'),
                    Text('Progress: ${(progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                trailing: Column(
                  children: [
                    // Button to update status
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () => updateStatus(reportId, 'Resolved'),
                    ),
                    // Progress bar to track repair progress
                    LinearProgressIndicator(value: progress),
                    ElevatedButton(
                      onPressed: () {
                        // Show a dialog to update progress
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Update Progress'),
                            content: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: 'Progress (0-100)'),
                              onChanged: (value) {
                                final progressValue = double.tryParse(value) ?? 0.0;
                                updateProgress(reportId, progressValue / 100);
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text('Update Progress'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
