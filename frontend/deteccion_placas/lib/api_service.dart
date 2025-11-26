import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Servicio reutilizable para llamadas HTTP
class ApiService {
  // Cambia esta URL según tu configuración
  static const String _baseUrl = 'https://andra-nonlethargic-noncommunistically.ngrok-free.dev';

  // --- GETTER AÑADIDO ---
  static String get baseUrl => _baseUrl;
  // ----------------------

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<bool> testConnection(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/health')).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Método GET reutilizable
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw 'Error GET $endpoint: $e';
    }
  }

  // Método POST reutilizable
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _defaultHeaders,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw 'Error POST $endpoint: $e';
    }
  }

  // Manejo de respuestas
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        return json.decode(response.body);
      } catch (e) {
        // Si la respuesta no es JSON, verificar si es HTML
        if (response.body.contains('<!DOCTYPE html>')) {
          throw 'El endpoint devuelve HTML en lugar de JSON. Verifica la URL.';
        }
        throw 'Respuesta no es JSON válido: ${response.body}';
      }
    } else {
      throw 'Error ${response.statusCode}: ${response.body}';
    }
  }
}