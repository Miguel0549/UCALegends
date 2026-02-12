import 'dart:convert';
import 'dart:ffi';
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

  static Future<http.Response?> get(String endpoint) async {
    return await _authenticatedRequest('GET', endpoint);
  }

  static Future<http.Response?> post(String endpoint, Map<String, dynamic> body) async {
    return await _authenticatedRequest('POST', endpoint, body: body);
  }

  static Future<http.Response?> delete(String endpoint, Map<String, dynamic> body) async {
    return await _authenticatedRequest('DELETE', endpoint, body: body);
  }

  static Future<http.Response?> put(String endpoint, Map<String, dynamic> body) async {
    return await _authenticatedRequest('PUT', endpoint, body: body);
  }

// --- EL "CEREBRO" DEL SILENT REFRESH ---
  static Future<http.Response?> _authenticatedRequest(
      String method,
      String endpoint,
      {Map<String, dynamic>? body}
      ) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // Función interna para no repetir código entre el primer intento y el reintento
    Future<http.Response> makeRequest(String? token) async {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      switch (method) {
        case 'POST':   return await http.post(url, headers: headers, body: jsonEncode(body));
        case 'GET':    return await http.get(url, headers: headers);
        case 'DELETE': return await http.delete(url, headers: headers, body: jsonEncode(body));
        case 'PUT':    return await http.put(url, headers: headers, body: jsonEncode(body));
        default:       return await http.get(url, headers: headers);
      }
    }

    // 1. Primer intento
    String? token = await getAccessToken();
    http.Response response;
    try {
      response = await makeRequest(token);
    } catch (e) {
      return null; // Error de red
    }

    // 2. ¿Token caducado? (401)
    if (response.statusCode == 401) {
      print("Acceso denegado (401). Intentando refrescar...");

      bool success = await _tryRefreshToken();

      if (success) {
        print("Refresco exitoso. Reintentando $method...");
        // 3. SEGUNDO INTENTO (Ahora con el nuevo token)
        String? newToken = await getAccessToken();
        return await makeRequest(newToken); // ¡Aquí ya se manejan todos los métodos!
      } else {
        print("Sesión expirada definitivamente.");
        await logout();
        return response;// Sigue siendo 401
      }
    }

    return response;
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

  static Future<Map<String, dynamic>?> getProfileUser( int id ) async {
    final data = await _authenticatedGet('/users/$id');
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

  static Future<List<dynamic>> getTeamMembers(int teamId) async {
    try {
      final response = await _authenticatedGet('/teams/$teamId/members');

      // Si la respuesta es una lista, la devolvemos directamente
      if (response is List) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      print("Error obteniendo miembros: $e");
      return [];
    }
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

  // -----------------------------------------------------------------------
  // --- GESTIÓN DE EQUIPOS (NUEVO SISTEMA DE SOLICITUDES) ---
  // -----------------------------------------------------------------------

  // 1. SOLICITAR UNIRSE A UN EQUIPO
  // El usuario envía una petición al líder del equipo
  static Future<bool> requestJoinTeam(int teamId) async {
    final token = await getAccessToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teams/$teamId/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error al solicitar unirse: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción solicitando unirse: $e");
      return false;
    }
  }

  static Future<bool> transferLeadership(int newLeaderId) async {
    final token = await getAccessToken();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teams/leader/$newLeaderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error transfiriendo liderazgo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción transfiriendo liderazgo: $e");
      return false;
    }
  }

  static Future<bool> dissolveTeam() async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/teams/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // 2. ECHAR A UN MIEMBRO (Solo Líder)
  static Future<bool> kickMember(int playerId) async {
    final token = await getAccessToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/teams/kick/$playerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error al expulsar miembro: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción al expulsar: $e");
      return false;
    }
  }

  // 3. OBTENER LISTA DE SOLICITUDES PENDIENTES (Solo Líder)
  static Future<List<dynamic>> getTeamRequests() async {
    final token = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teams/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Devuelve la lista de solicitudes
      } else {
        print("Error obteniendo solicitudes: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Excepción obteniendo solicitudes: $e");
      return [];
    }
  }

  // 4. RESPONDER A UNA SOLICITUD (Aceptar o Rechazar)
  static Future<bool> respondRequest(int requestId, bool accept) async {
    final token = await getAccessToken();
    final action = accept ? "accept" : "reject";

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teams/requests/$requestId/$action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error respondiendo solicitud: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción respondiendo solicitud: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getTournamentHistory() async {
    final token = await getAccessToken();
    try {
      // Llamada al endpoint real. Forzamos 'EUW' por ahora.
      final response = await http.get(
        Uri.parse('$baseUrl/tournaments/history?region=EUW'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decodificamos la lista de DTOs que envía Java
        return jsonDecode(response.body);
      } else {
        print("Error historial: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Excepción historial: $e");
      return [];
    }
  }

  // En ApiService.dart

  static Future<bool> createTournament({
    required String name,
    required String region,
    required String gameMode,
    required int maxTeams,
    required DateTime fechaInscripciones,
    required DateTime fechaInicio,
  }) async {
    final token = await getAccessToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tournaments/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name": name,
          "region": region,
          "gameMode": gameMode,
          "maxTeams": maxTeams,
          // Convertimos fechas a formato ISO para Java
          "fechaInscripciones": fechaInscripciones.toIso8601String(),
          "fechaInicio": fechaInicio.toIso8601String(),
          // Status se pone en backend, Winner y Rondas son null/0 por defecto
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error creando torneo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción: $e");
      return false;
    }
  }

// Método para saber si es admin (si no lo tenías ya)
  static Future<bool> isUserAdmin() async {
    final token = await getAccessToken();
    if (token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] == 'ROLE_ADMIN';
      }
    } catch (_) {}
    return false;
  }

}