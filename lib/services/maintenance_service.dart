import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> scheduleMaintenance(Map<String, dynamic> maintenanceData) async {
    await _firestore.collection("maintenance_schedules").add(maintenanceData);
  }

  Stream<QuerySnapshot> getMaintenanceTasks(String technicianId) {
    return _firestore.collection("maintenance_schedules").where("technician_id", isEqualTo: technicianId).snapshots();
  }
}
