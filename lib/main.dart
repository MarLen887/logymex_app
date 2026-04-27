import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const LogymexApp(),
    ),
  );
}

class LogymexApp extends StatelessWidget {
  const LogymexApp({super.key});

  // Función asíncrona para auditar la memoria local antes de renderizar la UI
  Future<bool> _checkAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOGYMEX Ambiental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColor),
        ),
        useMaterial3: true,
      ),
      // Interceptor de rutas basado en el estado de la promesa
      home: FutureBuilder<bool>(
        future: _checkAuthToken(),
        builder: (context, snapshot) {
          // Fase 1: Estado de espera (Indicador de carga)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryColor),
                ),
              ),
            );
          }
          // Fase 2: Redirección condicional
          if (snapshot.hasData && snapshot.data == true) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}