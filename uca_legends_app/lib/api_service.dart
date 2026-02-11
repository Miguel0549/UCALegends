import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ IMPORTANTE: Usa 10.0.2.2 para Emulador Android.
  // Si usas móvil físico, pon la IP de tu PC (ej: 192.168.1.35)
  static const String baseUrl = 'http://192.168.77.91:8081/api';

  static const _storage = FlutterSecureStorage();

  // --- GESTIÓN DE TOKENS ---

  static Future<String?> getAccessToken() async => await _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() async => await _storage.read(key: 'refresh_token');

  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<void> logout() async {
    // 1. Recuperamos el token ANTES de borrar nada
    final token = await getAccessToken();

    // 2. Intentamos avisar al Backend (si tenemos token)
    if (token != null) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        // IMPORTANTE: Si falla la conexión o el server está caído,
        // no hacemos nada. Queremos borrar los datos locales de todas formas.
        print("Error al cerrar sesión en servidor: $e");
      }
    }

    // 3. Borramos los datos locales pase lo que pase
    await _storage.deleteAll();
  }

  // --- AUTH ---

  static Future<bool> verifyToken() async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'), // Asegúrate que la ruta coincida con tu Controller
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Si hay error de red (servidor apagado), asumimos false para obligar login
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(data['access_token'], data['refresh_token']);
      return true;
    }
    return false;
  }

  static Future<bool> register(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('access_token') && data.containsKey('refresh_token')) {
        await _saveTokens(data['access_token'], data['refresh_token']);
      }
      return true;
    }
    return false;
  }

  // --- SISTEMA DE PETICIONES AUTENTICADAS (CORE) ---

  static Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String newAccess = data['access_token'];
      String newRefresh = data['refresh_token'] ?? refreshToken;
      await _saveTokens(newAccess, newRefresh);
      return true;
    } else {
      await logout();
      return false;
    }
  }

  // Wrapper genérico para GET
  static Future<dynamic> _authenticatedGet(String endpoint) async {
    String? token = await getAccessToken();

    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 403 || response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        token = await getAccessToken();
        response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    }

    if (response.statusCode == 200) {
      // Decodificamos UTF-8 para que salgan bien las tildes y ñ
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // --- MÉTODOS DE DATOS ---

  static Future<List<dynamic>> getHistory(String region) async {
    final data = await _authenticatedGet('/tournaments/history?region=$region');
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getTournaments() async {
    final data = await _authenticatedGet('/tournaments/');
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getCurrentMatches(int tournamentId) async {
    final data = await _authenticatedGet('/tournaments/$tournamentId/matches/current');
    return data is List ? data : [];
  }

  // --- PERFIL Y JUGADOR ---

  static Future<Map<String, dynamic>?> getMe() async {
    final data = await _authenticatedGet('/users/me');
    return data is Map<String, dynamic> ? data : null;
  }

  static Future<bool> createDevPlayer(Map<String, dynamic> playerData) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/players/dev/link'), // Asegúrate que la ruta coincide con Java
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(playerData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error linking: ${response.body}");
      return false;
    }
  }

  static Future<bool> unlinkRiotAccount() async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/players/dev/unlink'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // --- EQUIPOS (LOS QUE TE FALTABAN) ---

  // 1. Obtener todos los equipos (para el buscador)
  static Future<List<dynamic>> getAllTeams() async {
    // Nota: Asegúrate de haber añadido el endpoint @GetMapping("/") en TeamController
    // Si no lo hiciste, añade el método en Java o usa otro endpoint que devuelva lista.
    final data = await _authenticatedGet('/teams/');
    return data is List ? data : [];
  }

  // 2. Crear Equipo
  static Future<bool> createTeam(String name, String tag, String region) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/teams/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'tag': tag,
        'region': region
      }),
    );
    return response.statusCode == 200;
  }

  // 3. Unirse a Equipo
  static Future<bool> joinTeam(int teamId) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/teams/$teamId/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // 4. Salir de Equipo
  static Future<bool> leaveTeam() async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/teams/leave'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}