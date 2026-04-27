import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ReportService {
  // OPERACIÓN DE ESCRITURA (POST) - Ya validada
  Future<bool> createReport(String client, String wasteType, double weight) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final String tituloReporte = 'Manifiesto RPBI - $client';
      final String descripcionReporte = 'Clasificación: $wasteType | Peso neto: $weight kg';

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/reports'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'titulo': tituloReporte,
          'tipo': 'Recolección',
          'descripcion': descripcionReporte,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en la red (POST): $e');
      return false;
    }
  }

  // OPERACIÓN DE LECTURA (GET) - Nueva implementación
  Future<List<dynamic>> fetchAssignedRoutes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Token de sesión no encontrado.');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/reports'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decodifica la matriz JSON proveniente del servidor NestJS
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Fallo al obtener los registros HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en la red (GET): $e');
      // Retorna una lista vacía en caso de colapso para evitar un fallo crítico en la UI
      return []; 
    }
  }
}