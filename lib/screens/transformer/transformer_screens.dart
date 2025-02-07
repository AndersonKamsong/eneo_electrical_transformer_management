import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_transformer_screen.dart'; // Screen for adding a transformer
import 'edit_transformer_screen.dart'; // Screen for editing a transformer
import 'transformer_detail_screen.dart'; // Screen for  a transformer detail
import '../../services/transformer_service.dart';

class TransformerManagementScreen extends StatefulWidget {
  @override
  _TransformerManagementScreenState createState() => _TransformerManagementScreenState();
}

class _TransformerManagementScreenState extends State<TransformerManagementScreen> {
  final TransformerService _service = TransformerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transformer Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTransformerScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.fetchTransformers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transformers = snapshot.data ?? [];
          if (transformers.isEmpty) {
            return Center(child: Text('No transformers available'));
          }

          return ListView.builder(
            itemCount: transformers.length,
            itemBuilder: (context, index) {
              final transformer = transformers[index];
              return Card(
                child: ListTile(
                  title: Text(transformer['location'] ?? 'Unknown Location'),
                  subtitle: Text('Capacity: ${transformer['capacity']} - Status: ${transformer['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransformerDetailsScreen(transformerData: transformer),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditTransformerScreen(transformerData: transformer),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _service.deleteTransformer(transformer['id']);
                          setState(() {}); // Refresh list after deletion
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
