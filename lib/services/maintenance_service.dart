import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all tasks
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    QuerySnapshot snapshot = await _db.collection('maintenance_tasks').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Get a single task by its taskId
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    DocumentSnapshot doc = await _db.collection('maintenance_tasks').doc(taskId).get();
    return doc.data() as Map<String, dynamic>;
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _db.collection('maintenance_tasks').doc(taskId).update({
      'status': status,
    });
  }

  // Assign task to a technician
  Future<void> assignTask(String taskId, String technicianId) async {
    await _db.collection('maintenance_tasks').doc(taskId).update({
      'assigned_to': technicianId,
    });
  }
}
