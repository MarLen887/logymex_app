import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/waste_service.dart';

class WastesView extends StatefulWidget {
  const WastesView({super.key});

  @override
  State<WastesView> createState() => _WastesViewState();
}

class _WastesViewState extends State<WastesView> {
  final WasteService _wasteService = WasteService();
  late Future<List<dynamic>> _wastesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _wastesFuture = _wasteService.fetchWastes();
    });
  }

  // Formulario unificado paramétrico. Si 'existingWaste' es provisto, activa el modo edición.
  void _showWasteFormModal({Map<String, dynamic>? existingWaste}) {
    final _formKey = GlobalKey<FormState>();
    final isEditing = existingWaste != null;
    
    // Asignación referencial o inicialización nula
    final TextEditingController _nombreController = TextEditingController(text: isEditing ? existingWaste['nombre'] : '');
    final TextEditingController _clasificacionController = TextEditingController(text: isEditing ? existingWaste['clasificacion'] : '');
    
    String _tipo = isEditing ? existingWaste['tipo'] : 'RPBI';
    String _unidadMedida = isEditing ? existingWaste['unidadMedida'] : 'Kilogramos';
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Modificar Registro Maestro' : 'Alta de Residuo',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Residuo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.science),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Dato requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tipo,
                            decoration: const InputDecoration(
                              labelText: 'Tipo Normativo',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'RPBI', child: Text('RPBI')),
                              DropdownMenuItem(value: 'CRETIB', child: Text('CRETIB')),
                            ],
                            onChanged: (value) => setModalState(() => _tipo = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unidadMedida,
                            decoration: const InputDecoration(
                              labelText: 'Medida',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Kilogramos', child: Text('Kilogramos')),
                              DropdownMenuItem(value: 'Litros', child: Text('Litros')),
                              DropdownMenuItem(value: 'Piezas', child: Text('Piezas')),
                            ],
                            onChanged: (value) => setModalState(() => _unidadMedida = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _clasificacionController,
                      decoration: const InputDecoration(
                        labelText: 'Clasificación (Ej. Patológico)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Dato requerido' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.primaryColor),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSubmitting ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setModalState(() => _isSubmitting = true);
                            
                            bool success;
                            
                            // Orquestación de la petición según el estado del formulario
                            if (isEditing) {
                              success = await _wasteService.updateWaste(
                                existingWaste['id'],
                                _nombreController.text.trim(),
                                _tipo,
                                _clasificacionController.text.trim(),
                                _unidadMedida,
                              );
                            } else {
                              success = await _wasteService.createWaste(
                                _nombreController.text.trim(),
                                _tipo,
                                _clasificacionController.text.trim(),
                                _unidadMedida,
                              );
                            }

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(modalContext);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing ? 'Registro actualizado con precisión.' : 'Residuo catalogado exitosamente.'), 
                                  backgroundColor: Colors.green
                                ),
                              );
                            } else {
                              setModalState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error de mutación. Verifique conexión al servidor.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isEditing ? 'ACTUALIZAR REGISTRO' : 'GUARDAR EN CATÁLOGO'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        onPressed: () => _showWasteFormModal(), // Invocación sin parámetros (Modo Creación)
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Residuo'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<dynamic>>(
          future: _wastesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Excepción en lectura: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final List<dynamic> wastes = snapshot.data ?? [];

            if (wastes.isEmpty) {
              return const Center(child: Text('Catálogo de residuos vacío.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: wastes.length,
              itemBuilder: (context, index) {
                final item = wastes[index];
                final String nombre = item['nombre'] ?? 'Sin nomenclatura';
                final String tipo = item['tipo'] ?? 'N/A';
                final String clasificacion = item['clasificacion'] ?? '-';
                final String unidad = item['unidadMedida'] ?? 'U';

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tipo == 'RPBI' ? Colors.red.shade100 : Colors.blue.shade100,
                      child: Icon(
                        Icons.biotech,
                        color: tipo == 'RPBI' ? Colors.red : Colors.blue,
                      ),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Clasificación: $clasificacion | Unidad: $unidad'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(tipo, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: tipo == 'RPBI' ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        // Botón de edición que inyecta el objeto actual al modal
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _showWasteFormModal(existingWaste: item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}