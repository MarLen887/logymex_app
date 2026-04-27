import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class LogService {
  // Operación de inserción transaccional (POST)
  Future<bool> createLog(String cliente, double cantidad, String unidadId, String residuoId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/logs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'cliente': cliente,
          'cantidad': cantidad,
          'unidadId': unidadId,
          'residuoId': residuoId,
          // El 'operadorId' se omite delegando su inyección a la capa de seguridad de NestJS
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en la red (Bitácora POST): $e');
      return false;
    }
  }

  // Operación de extracción del historial (GET)
  Future<List<dynamic>> fetchLogs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Sesión criptográfica inválida.');

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/logs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fallo al obtener la bitácora: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en la red (Bitácora GET): $e');
      return [];
    }
  }
}