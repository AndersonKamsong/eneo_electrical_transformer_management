import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/transformer_service.dart';

class EditTransformerScreen extends StatefulWidget {
  final Map<String, dynamic> transformerData;

  const EditTransformerScreen({Key? key, required this.transformerData}) : super(key: key);

  @override
  _EditTransformerScreenState createState() => _EditTransformerScreenState();
}

class _EditTransformerScreenState extends State<EditTransformerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _capacityController;
  late TextEditingController _locationController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  DateTime? _installationDate;
  String? _status;
  final TransformerService _transformerService = TransformerService();

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController(text: widget.transformerData['capacity']);
    _locationController = TextEditingController(text: widget.transformerData['location']);
    _latitudeController = TextEditingController(text: widget.transformerData['latitude'].toString());
    _longitudeController = TextEditingController(text: widget.transformerData['longitude'].toString());
    _installationDate = (widget.transformerData['installationDate'] as Timestamp).toDate();
    _status = widget.transformerData['status'];
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _updateTransformer() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _transformerService.updateTransformer(
          id: widget.transformerData['id'],
          capacity: _capacityController.text,
          location: _locationController.text,
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          installationDate: _installationDate!,
          status: _status!,
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating transformer: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Transformer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(labelText: 'Capacity'),
                validator: (value) => value!.isEmpty ? 'Enter transformer capacity' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter latitude' : null,
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter longitude' : null,
              ),
              ListTile(
                title: Text(_installationDate != null
                    ? 'Installation Date: ${DateFormat.yMMMd().format(_installationDate!)}'
                    : 'Pick Installation Date'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _installationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _installationDate = pickedDate;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['Active', 'Under Maintenance', 'Faulty']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                decoration: InputDecoration(labelText: 'Status'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTransformer,
                child: Text('Update Transformer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
