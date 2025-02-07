import 'package:cloud_firestore/cloud_firestore.dart';

class FaultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportFault(Map<String, dynamic> faultData) async {
    await _firestore.collection("fault_reports").add(faultData);
  }

  Stream<QuerySnapshot> getFaultReports() {
    return _firestore.collection("fault_reports").snapshots();
  }
}
