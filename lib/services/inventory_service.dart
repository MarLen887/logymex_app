import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class InventoryService {
  // CREATE: Registro de movimientos
  Future<bool> createMovement(String residuoId, String tipoMovimiento, double cantidad) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/inventory'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'residuoId': residuoId,
          'tipoMovimiento': tipoMovimiento,
          'cantidad': cantidad,
        }),
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  // READ: Obtención de la lista
  Future<List<dynamic>> fetchInventory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/inventory'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // UPDATE: Edición de movimientos existentes
  Future<bool> updateMovement(String id, String residuoId, String tipoMovimiento, double cantidad) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${AppConstants.apiUrl}/inventory/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'residuoId': residuoId,
          'tipoMovimiento': tipoMovimiento,
          'cantidad': cantidad,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // DELETE: Eliminación física/lógica del registro
  Future<bool> deleteMovement(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/inventory/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}