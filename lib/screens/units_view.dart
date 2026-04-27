import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/unit_service.dart';

class UnitsView extends StatefulWidget {
  const UnitsView({super.key});

  @override
  State<UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<UnitsView> {
  final UnitService _unitService = UnitService();
  late Future<List<dynamic>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _unitsFuture = _unitService.fetchUnits();
    });
  }

  void _showAddUnitModal() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _placasController = TextEditingController();
    final TextEditingController _marcaController = TextEditingController();
    final TextEditingController _modeloController = TextEditingController();
    
    String _estatus = 'Libre';
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
                    const Text(
                      'Registrar Unidad Vehicular',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _placasController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Placas / Matrícula',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _marcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _modeloController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Modelo (Año)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _estatus,
                      decoration: const InputDecoration(
                        labelText: 'Estatus Operativo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.traffic),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Libre', child: Text('Libre')),
                        DropdownMenuItem(value: 'En Ruta', child: Text('En Ruta')),
                        DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                      ],
                      onChanged: (value) => setModalState(() => _estatus = value!),
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
                            
                            final bool success = await _unitService.createUnit(
                              _placasController.text.trim().toUpperCase(),
                              _marcaController.text.trim(),
                              _modeloController.text.trim(),
                              _estatus,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(modalContext);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Unidad registrada exitosamente.'), backgroundColor: Colors.green),
                              );
                            } else {
                              setModalState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fallo en el registro.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('GUARDAR UNIDAD'),
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

  // Método para desplegar el diálogo de actualización de estado
  void _showUpdateStatusDialog(String unitId, String currentStatus, String unitName) {
    String selectedStatus = currentStatus;
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Modificar Estatus Operativo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unidad: $unitName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo Estatus',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Libre', child: Text('Libre')),
                      DropdownMenuItem(value: 'En Ruta', child: Text('En Ruta')),
                      DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUpdating ? null : () async {
                    setStateDialog(() => isUpdating = true);
                    
                    final success = await _unitService.updateUnitStatus(unitId, selectedStatus);
                    
                    if (!context.mounted) return;
                    
                    if (success) {
                      Navigator.pop(dialogContext);
                      _refreshData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Estatus actualizado correctamente.'), backgroundColor: Colors.green),
                      );
                    } else {
                      setStateDialog(() => isUpdating = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fallo al actualizar el estatus.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: isUpdating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ACTUALIZAR'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Libre': return Colors.green;
      case 'En Ruta': return Colors.orange;
      case 'Mantenimiento': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        onPressed: _showAddUnitModal,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Unidad'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<dynamic>>(
          future: _unitsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final List<dynamic> units = snapshot.data ?? [];

            if (units.isEmpty) {
              return const Center(child: Text('No hay unidades vehiculares registradas.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final item = units[index];
                final String id = item['id']?.toString() ?? '';
                final String placas = item['placas'] ?? 'N/A';
                final String marca = item['marca'] ?? 'Desconocida';
                final String modelo = item['modelo'] ?? '';
                final String estatus = item['estatus'] ?? 'Libre';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    // Invocación del cuadro de diálogo al presionar la tarjeta
                    onTap: () {
                      if (id.isNotEmpty) {
                        _showUpdateStatusDialog(id, estatus, '$marca $modelo');
                      }
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.local_shipping,
                        size: 40,
                        color: _getStatusColor(estatus),
                      ),
                      title: Text('$marca $modelo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Placas: $placas\nToque para cambiar estatus'),
                      isThreeLine: true,
                      trailing: Chip(
                        label: Text(
                          estatus,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: _getStatusColor(estatus),
                      ),
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