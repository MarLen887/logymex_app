import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'usuario': username,
          'contrasena': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String token = responseData['access_token'];
        
        // Extracción del sub-objeto del usuario
        final Map<String, dynamic> userData = responseData['user'];

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        
        // Persistencia de los datos de identidad
        await prefs.setString('user_nombres', userData['nombres'] ?? '');
        await prefs.setString('user_apellidos', userData['apellidos'] ?? '');
        await prefs.setString('user_rol', userData['rol'] ?? 'OPERADOR');

        return true;
      } else {
        print('Error del servidor: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en la capa de red: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Purga total de la sesión (token y variables de identidad)
  }
}