import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/log_service.dart';
import '../services/unit_service.dart';
import '../services/waste_service.dart';

class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final LogService _logService = LogService();
  final UnitService _unitService = UnitService();
  final WasteService _wasteService = WasteService();
  
  late Future<List<dynamic>> _logsFuture;
  
  // Matrices de datos maestros para la integridad referencial
  List<dynamic> _unitsCatalog = [];
  List<dynamic> _wastesCatalog = [];
  bool _isLoadingCatalogs = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadCatalogsConcurrently();
  }

  void _refreshData() {
    setState(() {
      _logsFuture = _logService.fetchLogs();
    });
  }

  // Orquestación paralela para mitigar latencia
  Future<void> _loadCatalogsConcurrently() async {
    try {
      final results = await Future.wait([
        _unitService.fetchUnits(),
        _wasteService.fetchWastes(),
      ]);
      
      if (mounted) {
        setState(() {
          _unitsCatalog = results[0];
          _wastesCatalog = results[1];
          _isLoadingCatalogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCatalogs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al sincronizar catálogos relacionales.')),
        );
      }
    }
  }

  void _showAddLogModal() {
    if (_isLoadingCatalogs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronizando modelos de dominio. Por favor, espere.')),
      );
      return;
    }

    if (_unitsCatalog.isEmpty || _wastesCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restricción: Requiere al menos un vehículo y un residuo en el sistema.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final _formKey = GlobalKey<FormState>();
    final TextEditingController _clienteController = TextEditingController();
    final TextEditingController _cantidadController = TextEditingController();
    
    String _unidadId = _unitsCatalog.first['id']?.toString() ?? '';
    String _residuoId = _wastesCatalog.first['id']?.toString() ?? '';
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
                      'Registro en Bitácora Operativa',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _clienteController,
                      decoration: const InputDecoration(
                        labelText: 'Entidad Cliente / Generador',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Selector relacional de Flota Vehicular
                    DropdownButtonFormField<String>(
                      value: _unidadId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de Transporte Asignada',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      items: _unitsCatalog.map<DropdownMenuItem<String>>((dynamic unit) {
                        final String uId = unit['id']?.toString() ?? '';
                        final String uPlacas = unit['placas']?.toString() ?? 'N/A';
                        final String uMarca = unit['marca']?.toString() ?? 'Desconocida';
                        return DropdownMenuItem<String>(
                          value: uId,
                          child: Text('[$uPlacas] - $uMarca', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => _unidadId = value!),
                    ),
                    const SizedBox(height: 16),

                    // Selector relacional de Catálogo de Residuos
                    DropdownButtonFormField<String>(
                      value: _residuoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Clasificación de Residuo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.biotech),
                      ),
                      items: _wastesCatalog.map<DropdownMenuItem<String>>((dynamic waste) {
                        final String wId = waste['id']?.toString() ?? '';
                        final String wNombre = waste['nombre']?.toString() ?? 'Desconocido';
                        return DropdownMenuItem<String>(
                          value: wId,
                          child: Text(wNombre, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => _residuoId = value!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Volumen Recolectado (Numérico)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Dato mandatorio';
                        if (double.tryParse(value) == null) return 'Magnitud inválida';
                        return null;
                      },
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
                            
                            final bool success = await _logService.createLog(
                              _clienteController.text.trim(),
                              double.parse(_cantidadController.text),
                              _unidadId,
                              _residuoId,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(modalContext);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bitácora actualizada exitosamente.'), backgroundColor: Colors.green),
                              );
                            } else {
                              setModalState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fallo de inserción en servidor.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('REGISTRAR EN BITÁCORA'),
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
        onPressed: _showAddLogModal,
        icon: const Icon(Icons.assignment),
        label: const Text('Nuevo Registro'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await _loadCatalogsConcurrently();
        },
        child: FutureBuilder<List<dynamic>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Excepción: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final List<dynamic> logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return const Center(child: Text('La bitácora operativa se encuentra vacía.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final item = logs[index];
                final String cliente = item['cliente'] ?? 'Desconocido';
                final String cantidad = item['cantidad']?.toString() ?? '0';
                
                // NestJS podría devolver las entidades pobladas o solo los IDs.
                // Ajustaremos la lectura asumiendo que retorna un objeto anidado o un string genérico.
                final String vehiculoInfo = item['unidad'] != null ? item['unidad']['placas'] : 'Ver detalles';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(AppConstants.primaryColor),
                      child: Icon(Icons.assignment_turned_in, color: Colors.white),
                    ),
                    title: Text(cliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Volumen: $cantidad | Vehículo: $vehiculoInfo'),
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