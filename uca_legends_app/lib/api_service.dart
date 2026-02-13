import 'dart:async';
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

  static Future<http.Response?> delete(String endpoint) async {
    return await _authenticatedRequest('DELETE', endpoint);
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
        'Authorization': 'Bearer ${token ?? ""}',
      };

      switch (method) {
        case 'POST':   return await http.post(url, headers: headers, body: jsonEncode(body));
        case 'GET':    return await http.get(url, headers: headers);
        case 'DELETE': return await http.delete(url, headers: headers, body: jsonEncode(body));
        case 'PUT':    return await http.put(url, headers: headers, body: jsonEncode(body));
        default:       return await http.get(url, headers: headers);
      }
    }

    String? token = await getAccessToken();

    // 1. Primer intento
    http.Response response;
    try {
      response = await makeRequest(token);
    } catch (e) {
      return null; // Error de red
    }

    // 2. ¿Token caducado? (401)
    if (response.statusCode == 401 || response.statusCode == 403) {
      print("Acceso denegado (401). Intentando refrescar...");

      bool success = await tryRefreshToken();

      if (success) {
        print("Refresco exitoso. Reintentando $method...");
        // 3. SEGUNDO INTENTO (Ahora con el nuevo token)
        String? newToken = await getAccessToken();
        return await makeRequest(newToken); // ¡Aquí ya se manejan todos los métodos!
      } else {
        print("Sesión expirada definitivamente.");
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
    if (token == null) {
      return false;
    }

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

  static Completer<bool>? _refreshCompleter;

  static Future<bool> tryRefreshToken() async {
    // 2. Si ya hay alguien refrescando, NO LLAMES AL SERVIDOR. Espera al que ya está en camino.
    if (_refreshCompleter != null) {
      print("Ya hay un refresco en curso. Esperando...");
      return _refreshCompleter!.future;
    }

    // 3. Soy el primero en llegar, creo la sala de espera
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(false); // Aviso a los que esperan que falló
        _refreshCompleter = null; // Libero la sala
        await logout();
        return false;
      }

      print("Llamando al servidor para refrescar token...");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access_token'], data['refresh_token'] ?? refreshToken);

        // 4. ¡Éxito! Aviso a todos los que estaban esperando (B y C)
        _refreshCompleter!.complete(true);
        _refreshCompleter = null; // Muy importante ponerlo a null para la próxima vez que caduque
        return true;
      } else {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        await logout();
        return false;
      }
    } catch (e) {
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
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
      final refreshed = await tryRefreshToken();
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
    final response = await get('/tournaments/history?region=$region');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> getTournaments() async {
    final response = await get('/tournaments/');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> getCurrentMatches(int tournamentId) async {
    final response = await get('/tournaments/$tournamentId/matches/current');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // --- PERFIL Y JUGADOR ---

  static Future<Map<String, dynamic>?> getMe() async {
    final response = await get('/users/me');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body); // Devuelve el List
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getProfileUser( int id ) async {
    final response = await get('/users/$id');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body); // Devuelve el List
    }

    return null;
  }

  static Future<bool> createDevPlayer(Map<String, dynamic> playerData) async {
    final response = await post('/players/dev/link',playerData);

    if ( response != null ){
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error linking: ${response.body}");
        return false;
      }
    }

    return false;

  }

  static Future<bool> unlinkRiotAccount() async {
    final response = await delete('/players/dev/unlink');
    if ( response != null ) return response.statusCode == 200;
    return false;
  }

  // --- EQUIPOS (LOS QUE TE FALTABAN) ---

  // 1. Obtener todos los equipos (para el buscador)
  static Future<List<dynamic>> getAllTeams() async {
    final response = await get('/teams/');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // 2. Crear Equipo
  static Future<bool> createTeam(String name, String tag, String region) async {

    Map<String,dynamic> body = new Map.of({
      'name': name,
      'tag': tag,
      'region': region});

    final response = await post('/teams/create', body);

    if ( response != null ){
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error creating team: ${response.body}");
        return false;
      }
    }

    return false;
  }

  static Future<List<dynamic>> getTeamMembers(int teamId) async {
    try {
      final response = await get('/teams/$teamId/members');

      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("Error obteniendo miembros: $e");
      return [];
    }
  }

  // 4. Salir de Equipo
  static Future<bool> leaveTeam() async {
    final response = await post('/teams/leave',<String,dynamic>{});

    if ( response != null ){
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error leaving team: ${response.body}");
        return false;
      }
    }

    return false;
  }

  // -----------------------------------------------------------------------
  // --- GESTIÓN DE EQUIPOS (NUEVO SISTEMA DE SOLICITUDES) ---
  // -----------------------------------------------------------------------

  // 1. SOLICITAR UNIRSE A UN EQUIPO
  // El usuario envía una petición al líder del equipo
  static Future<bool> requestJoinTeam(int teamId) async {
    try {
      final response = await post('/teams/$teamId/request', <String,dynamic>{});

      if ( response != null ){
        if (response.statusCode == 200) {
          return true;
        } else {
          print("Error request team: ${response.body}");
          return false;
        }
      }

      return false;

    } catch (e) {
      print("Excepción solicitando unirse: $e");
      return false;
    }
  }

  static Future<bool> transferLeadership(int newLeaderId) async {
    try {
      final response = await post('/teams/leader/$newLeaderId',<String,dynamic>{});

      if ( response != null ){
        if (response.statusCode == 200) {
          return true;
        } else {
          print("Error transfering leadership: ${response.body}");
          return false;
        }
      }

      return false;

    } catch (e) {
      print("Excepción transfiriendo liderazgo: $e");
      return false;
    }
  }

  static Future<bool> dissolveTeam() async {
    final response = await delete('/teams/delete');
    if ( response != null ) return response.statusCode == 200;
    return false;
  }

  // 2. ECHAR A UN MIEMBRO (Solo Líder)
  static Future<bool> kickMember(int playerId) async {
    try {
      final response = await delete('/teams/kick/$playerId');
      if ( response != null ) return response.statusCode == 200;
      return false;

    } catch (e) {
      print("Excepción al expulsar: $e");
      return false;
    }
  }

  // 3. OBTENER LISTA DE SOLICITUDES PENDIENTES (Solo Líder)
  static Future<List<dynamic>> getTeamRequests() async {
    try {
      final response = await get('/teams/requests');

      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];

    } catch (e) {
      print("Excepción obteniendo solicitudes: $e");
      return [];
    }
  }

  // 4. RESPONDER A UNA SOLICITUD (Aceptar o Rechazar)
  static Future<bool> respondRequest(int requestId, bool accept) async {
    final action = accept ? "accept" : "reject";

    try {
      final response = await post('/teams/requests/$requestId/$action',<String,dynamic>{});

      if ( response != null ){
        if (response.statusCode == 200) {
          return true;
        } else {
          print("Error responding request: ${response.body}");
          return false;
        }
      }

      return false;

    } catch (e) {
      print("Excepción respondiendo solicitud: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getTournamentHistory() async {
    final token = await getAccessToken();
    try {
      // Llamada al endpoint real. Forzamos 'EUW' por ahora.
      final response = await get('/tournaments/history?region=EUW');

      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];

    } catch (e) {
      print("Excepción historial: $e");
      return [];
    }
  }

  static Future<bool> createTournament({
    required String name,
    required String region,
    required String gameMode,
    required int maxTeams,
    required DateTime fechaInscripciones,
    required DateTime fechaInicio,
  }) async {


    Map<String,dynamic> body = Map.of({
      "name": name,
      "region": region,
      "gameMode": gameMode,
      "maxTeams": maxTeams,
      "fechaInscripciones": fechaInscripciones.toIso8601String(),
      "fechaInicio": fechaInicio.toIso8601String(),});

    try {
      final response = await post('/tournaments/create',body);

      if ( response != null ){
        if (response.statusCode == 200) {
          return true;
        } else {
          print("Error creating tournament: ${response.body}");
          return false;
        }
      }

      return false;

    } catch (e) {
      print("Excepción: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getTournamentById(int id) async {
    final response = await get('/tournaments/$id');

    if (response != null && response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  static Future<int> getInscribedCount(int tournamentId) async {
    final response = await get('/tournaments/$tournamentId/count');

    if (response != null && response.statusCode == 200) {
      // Como el body es solo un número (Long), lo parseamos directamente
      return int.parse(response.body);
    }
    return 0;
  }

  static Future<String?> joinTournament(int id) async {
    final response = await post('/tournaments/$id/join', {});

    if (response != null) {
      if (response.statusCode == 200) {
        return "success"; // Inscripción correcta
      } else {
        // Devolvemos el mensaje de error que viene del backend (ej: "Ya estás inscrito")
        return response.body;
      }
    }
    return "Error de conexión";
  }

  static Future<List<dynamic>> getTournamentMatches(int tournamentId) async {
    try {
      final response = await get('/tournaments/$tournamentId/matches');

      if (response != null && response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print("Error obteniendo matches: $e");
      return [];
    }
  }

  static Future<String?> reportMatchResult(int matchId, String riotMatchId) async {
    final response = await post('/matches/$matchId/report', {'riotMatchId': riotMatchId});
    if (response != null) {
      if (response.statusCode == 200) return "success";
      return response.body; // Mensaje de error (ej: "Solo líderes pueden reportar")
    }
    return "Error de red";
  }

  static Future<bool> isUserAdmin() async {
    try {
      final response = await get('/users/me');

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] == 'ROLE_ADMIN';
      }
    } catch (_) {}
    return false;
  }

}