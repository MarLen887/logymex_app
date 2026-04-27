import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/report_service.dart';

class AssignedRoutesView extends StatefulWidget {
  const AssignedRoutesView({super.key});

  @override
  State<AssignedRoutesView> createState() => _AssignedRoutesViewState();
}

class _AssignedRoutesViewState extends State<AssignedRoutesView> {
  final ReportService _reportService = ReportService();
  late Future<List<dynamic>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = _reportService.fetchAssignedRoutes();
  }

  Future<void> _refreshData() async {
    setState(() {
      _routesFuture = _reportService.fetchAssignedRoutes();
    });
  }

  // Despliegue dinámico de metadatos de la ruta
  void _showRouteDetails(BuildContext context, String titulo, String tipo, String descripcion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(AppConstants.primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const Text('Tipo de Operación:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(tipo, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Especificaciones Técnicas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(descripcion, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CERRAR', style: TextStyle(color: Color(AppConstants.primaryColor))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(AppConstants.primaryColor),
      child: FutureBuilder<List<dynamic>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(AppConstants.primaryColor),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error de sincronización:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final List<dynamic> routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No existen rutas ni manifiestos asignados en este momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final String titulo = route['titulo'] ?? 'Sin identificador';
              final String tipo = route['tipo'] ?? 'Desconocido';
              final String descripcion = route['descripcion'] ?? 'Sin detalles adicionales';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            color: Color(AppConstants.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tipo,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          // Implementación funcional de la directriz de visualización
                          onPressed: () => _showRouteDetails(context, titulo, tipo, descripcion),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Ver Detalles'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(AppConstants.primaryColor),
                          ),
                        ),
                      )
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