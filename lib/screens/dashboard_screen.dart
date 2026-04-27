import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'manifest_capture_view.dart';
import 'assigned_routes_view.dart';
import 'inventory_view.dart';
import 'units_view.dart';
import 'logs_view.dart';
import 'wastes_view.dart'; // Importación del nuevo Catálogo Maestro

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  String _userNombres = 'Cargando...';
  String _userApellidos = '';
  String _userRol = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNombres = prefs.getString('user_nombres') ?? 'Operador';
      _userApellidos = prefs.getString('user_apellidos') ?? 'Logístico';
      _userRol = prefs.getString('user_rol') ?? 'operador';
    });
  }

  String _formatRole(String rawRole) {
    switch (rawRole.toLowerCase()) {
      case 'director_general':
        return 'Director General';
      case 'jefe_inmediato':
        return 'Jefe Inmediato';
      case 'operador':
        return 'Operador';
      default:
        return rawRole.toUpperCase();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).signSignOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedRole = _formatRole(_userRol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGYMEX - Operaciones'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(AppConstants.primaryColor),
              ),
              accountName: Text(
                '$_userNombres $_userApellidos',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text('Rol: $formattedRole'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Panel Principal'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.scale),
              title: const Text('Captura de Manifiestos RPBI'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Rutas Asignadas'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventario Almacén'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Flota Vehicular'),
              selected: _selectedIndex == 4,
              onTap: () => _onItemTapped(4),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Bitácora Operativa'),
              selected: _selectedIndex == 5,
              onTap: () => _onItemTapped(5),
            ),
            const Divider(),
            // Integración del Catálogo de Residuos
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Catálogo de Residuos'),
              selected: _selectedIndex == 6,
              onTap: () => _onItemTapped(6),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              selected: _selectedIndex == 7,
              onTap: () => _onItemTapped(7),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
      body: _buildBodyContent(formattedRole),
    );
  }

  Widget _buildBodyContent(String formattedRole) {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 80, color: Color(AppConstants.primaryColor)),
              const SizedBox(height: 20),
              Text(
                'Bienvenido, $_userNombres $_userApellidos',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rol Activo: $formattedRole',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return const ManifestCaptureView();
      case 2:
        return const AssignedRoutesView();
      case 3:
        return const InventoryView();
      case 4:
        return const UnitsView();
      case 5:
        return const LogsView();
      case 6:
        // Renderización del CRUD Maestro
        return const WastesView();
      default:
        return const Center(child: Text('Vista no encontrada o en construcción'));
    }
  }
}