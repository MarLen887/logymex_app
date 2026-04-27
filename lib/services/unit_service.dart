import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class UnitService {
  Future<bool> createUnit(String placas, String marca, String modelo, String estatus) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/units'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'placas': placas,
          'marca': marca,
          'modelo': modelo,
          'estatus': estatus,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en la red (Unidades POST): $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchUnits() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Sesión inválida.');

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/units'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fallo al obtener la flota: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en la red (Unidades GET): $e');
      return [];
    }
  }

  // Nueva Operación de Actualización (PATCH) para el estatus operativo
  Future<bool> updateUnitStatus(String id, String nuevoEstatus) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${AppConstants.apiUrl}/units/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'estatus': nuevoEstatus,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Excepción en la red (Unidades PATCH): $e');
      return false;
    }
  }
}