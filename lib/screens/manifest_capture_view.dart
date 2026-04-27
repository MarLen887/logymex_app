import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/report_service.dart';

class ManifestCaptureView extends StatefulWidget {
  const ManifestCaptureView({super.key});

  @override
  State<ManifestCaptureView> createState() => _ManifestCaptureViewState();
}

class _ManifestCaptureViewState extends State<ManifestCaptureView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final ReportService _reportService = ReportService();
  
  String? _selectedWasteType;
  bool _isLoading = false;

  final List<String> _wasteTypes = [
    'Sangre y Hemoderivados',
    'Cultivos y Cepas',
    'Patológicos',
    'Residuos No Anatómicos',
    'Objetos Punzocortantes'
  ];

  @override
  void dispose() {
    _clientController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String client = _clientController.text.trim();
      final double weight = double.parse(_weightController.text.trim());

      final bool success = await _reportService.createReport(
        client,
        _selectedWasteType!,
        weight,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manifiesto RPBI registrado con éxito en el servidor.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Purgado estructural tras el registro exitoso
        _clientController.clear();
        _weightController.clear();
        setState(() {
          _selectedWasteType = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar el manifiesto. Consulte la bitácora del servidor.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de Manifiesto RPBI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete los datos de recolección en el punto de generación.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            TextFormField(
              controller: _clientController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Cliente / Clínica',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El identificador del cliente es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Clasificación del Residuo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.biotech),
              ),
              value: _selectedWasteType,
              items: _wasteTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWasteType = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione una clasificación normativa válida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso Neto Recolectado (Kilogramos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El pesaje es un dato obligatorio.';
                }
                if (double.tryParse(value) == null) {
                  return 'Debe ingresar una magnitud numérica válida.';
                }
                if (double.parse(value) <= 0) {
                  return 'El peso debe ser superior a cero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'PROCESANDO...' : 'REGISTRAR MANIFIESTO',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}