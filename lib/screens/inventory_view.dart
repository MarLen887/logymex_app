import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/inventory_service.dart';
import '../services/waste_service.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final InventoryService _inventoryService = InventoryService();
  final WasteService _wasteService = WasteService();
  
  late Future<List<dynamic>> _inventoryFuture;
  List<dynamic> _wastesCatalog = [];
  bool _isLoadingWastes = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadWastesCatalog();
  }

  void _refreshData() {
    setState(() {
      _inventoryFuture = _inventoryService.fetchInventory();
    });
  }

  Future<void> _loadWastesCatalog() async {
    final wastes = await _wasteService.fetchWastes();
    if (mounted) {
      setState(() {
        _wastesCatalog = wastes;
        _isLoadingWastes = false;
      });
    }
  }

  // Formulario unificado para operaciones POST y PATCH
  void _showMovementFormModal({Map<String, dynamic>? existingMovement}) {
    if (_isLoadingWastes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronizando catálogo con el servidor...')),
      );
      return;
    }

    if (_wastesCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restricción: No existen residuos catalogados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool isEditing = existingMovement != null;
    final formKey = GlobalKey<FormState>();
    
    // Extracción de variables referenciales
    String tipoMovimiento = isEditing ? existingMovement['tipoMovimiento'] : 'ENTRADA';
    final TextEditingController cantidadController = TextEditingController(
      text: isEditing ? existingMovement['cantidad'].toString() : ''
    );
    
    // Resolución heurística de la llave foránea (residuoId)
    String residuoId = _wastesCatalog.first['id'].toString();
    if (isEditing) {
      // NestJS puede retornar el ID directo o el objeto anidado dependiendo de la configuración de TypeORM
      String extractedId = existingMovement['residuoId']?.toString() ?? 
                           existingMovement['residuo']?['id']?.toString() ?? '';
      
      // Validación estricta para evitar asimetría en el Dropdown
      bool existsInCatalog = _wastesCatalog.any((w) => w['id'].toString() == extractedId);
      if (existsInCatalog) {
        residuoId = extractedId;
      }
    }

    bool isSubmitting = false;

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
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Modificar Movimiento' : 'Registrar Movimiento',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: tipoMovimiento,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Movimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sync_alt),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ENTRADA', child: Text('ENTRADA (Acopio)')),
                        DropdownMenuItem(value: 'SALIDA', child: Text('SALIDA (Disposición)')),
                      ],
                      onChanged: (value) => setModalState(() => tipoMovimiento = value!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: residuoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Residuo Logístico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.biotech),
                      ),
                      items: _wastesCatalog.map<DropdownMenuItem<String>>((dynamic waste) {
                        final String wId = waste['id']?.toString() ?? '';
                        final String wNombre = waste['nombre']?.toString() ?? 'Desconocido';
                        final String wUnidad = waste['unidadMedida']?.toString() ?? 'U';
                        return DropdownMenuItem<String>(
                          value: wId,
                          child: Text('$wNombre ($wUnidad)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => residuoId = value!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Operativa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El parámetro es estrictamente requerido.';
                        if (double.tryParse(value) == null) return 'Ingrese una magnitud matemática válida.';
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
                        onPressed: isSubmitting ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setModalState(() => isSubmitting = true);
                            
                            bool success;
                            final double cantidadProcesada = double.parse(cantidadController.text);

                            // Condicional de mutación vs creación
                            if (isEditing) {
                              success = await _inventoryService.updateMovement(
                                existingMovement['id'],
                                residuoId,
                                tipoMovimiento,
                                cantidadProcesada,
                              );
                            } else {
                              success = await _inventoryService.createMovement(
                                residuoId,
                                tipoMovimiento,
                                cantidadProcesada,
                              );
                            }

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(modalContext);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing ? 'Movimiento actualizado con rigor.' : 'Transacción consolidada exitosamente.'), 
                                  backgroundColor: Colors.green
                                ),
                              );
                            } else {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rechazo del servidor. Consulte la integridad referencial.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isEditing ? 'ACTUALIZAR MOVIMIENTO' : 'GUARDAR MOVIMIENTO'),
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
        onPressed: () => _showMovementFormModal(), // Invocación sin argumentos
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Movimiento'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await _loadWastesCatalog();
        },
        child: FutureBuilder<List<dynamic>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Excepción de red: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final List<dynamic> inventory = snapshot.data ?? [];

            if (inventory.isEmpty) {
              return const Center(child: Text('Inventario sin movimientos registrados.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                final String tipo = item['tipoMovimiento'] ?? 'DESCONOCIDO';
                final String cantidad = item['cantidad']?.toString() ?? '0';
                final bool isEntrada = tipo == 'ENTRADA';

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEntrada ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isEntrada ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text('Movimiento: $tipo', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Volumen procesado: $cantidad'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      // Invocación del modal con inyección del objeto transaccional
                      onPressed: () => _showMovementFormModal(existingMovement: item),
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