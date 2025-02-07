import 'package:cloud_firestore/cloud_firestore.dart';

class TransformerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new transformer
  Future<void> addTransformer({
    required String id,
    required String capacity,
    required String location,
    required double latitude,
    required double longitude,
    required DateTime installationDate,
    required String status, // e.g., Active, Under Maintenance, Faulty
  }) async {
    try {
      await _firestore.collection('transformers').doc(id).set({
        'id': id,
        'capacity': capacity,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'installationDate': installationDate,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Transformer added successfully');
    } catch (e) {
      print('Error adding transformer: $e');
      throw e;
    }
  }

  // Update transformer details
  Future<void> updateTransformer({
    required String id,
    String? capacity,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? installationDate,
    String? status,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (capacity != null) updateData['capacity'] = capacity;
      if (location != null) updateData['location'] = location;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (installationDate != null) updateData['installationDate'] = installationDate;
      if (status != null) updateData['status'] = status;

      if (updateData.isNotEmpty) {
        await _firestore.collection('transformers').doc(id).update(updateData);
        print('Transformer updated successfully');
      }
    } catch (e) {
      print('Error updating transformer: $e');
      throw e;
    }
  }

  // Delete a transformer
  Future<void> deleteTransformer(String id) async {
    try {
      await _firestore.collection('transformers').doc(id).delete();
      print('Transformer deleted successfully');
    } catch (e) {
      print('Error deleting transformer: $e');
      throw e;
    }
  }

  // Fetch all transformers
  Future<List<Map<String, dynamic>>> fetchTransformers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('transformers').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching transformers: $e');
      throw e;
    }
  }

  // Fetch transformers by status (e.g., Active, Under Maintenance, Faulty)
  Future<List<Map<String, dynamic>>> fetchTransformersByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transformers')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching transformers by status: $e');
      throw e;
    }
  }

  // Fetch transformer by ID
  Future<Map<String, dynamic>?> fetchTransformerById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('transformers').doc(id).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print('Transformer not found');
        return null;
      }
    } catch (e) {
      print('Error fetching transformer by ID: $e');
      throw e;
    }
  }

  // Fetch transformers within a specific geographic area (for map integration)
  Future<List<Map<String, dynamic>>> fetchTransformersInArea({
    required double minLatitude,
    required double maxLatitude,
    required double minLongitude,
    required double maxLongitude,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transformers')
          .where('latitude', isGreaterThanOrEqualTo: minLatitude)
          .where('latitude', isLessThanOrEqualTo: maxLatitude)
          .where('longitude', isGreaterThanOrEqualTo: minLongitude)
          .where('longitude', isLessThanOrEqualTo: maxLongitude)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching transformers in area: $e');
      throw e;
    }
  }
}