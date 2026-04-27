import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class WasteService {
  Future<List<dynamic>> fetchWastes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Ausencia de credenciales criptográficas.');

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/waste'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fallo en la extracción de datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en red (Waste GET): $e');
      return [];
    }
  }

  Future<bool> createWaste(String nombre, String tipo, String clasificacion, String unidadMedida) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/waste'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'nombre': nombre,
          'tipo': tipo,
          'clasificacion': clasificacion,
          'unidadMedida': unidadMedida,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en red (Waste POST): $e');
      return false;
    }
  }

  // Nueva Operación de Mutación de Datos (PATCH)
  Future<bool> updateWaste(String id, String nombre, String tipo, String clasificacion, String unidadMedida) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${AppConstants.apiUrl}/waste/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'nombre': nombre,
          'tipo': tipo,
          'clasificacion': clasificacion,
          'unidadMedida': unidadMedida,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en red (Waste PATCH): $e');
      return false;
    }
  }
}