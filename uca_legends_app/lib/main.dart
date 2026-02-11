import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'api_service.dart'; // Importa el archivo que creamos arriba
import 'splash_screen.dart';

void main() {
  runApp(LegendsApp());
}

class LegendsApp extends StatelessWidget {
  const LegendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legends Tournament',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A0C),
        primaryColor: const Color(0xFFD32F2F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD32F2F),
          secondary: Color(0xFFC9AA71),
          surface: Color(0xFF1E2328),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}



class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = ApiService.getMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
        }

        final user = snapshot.data;
        if (user == null) return const Center(child: Text("Error cargando perfil"));

        final player = user['player'];

        // ESTADO 1: NO TIENE JUGADOR VINCULADO
        if (player == null) {
          return _buildLinkAccountForm();
        }

        // ESTADO 2: TIENE PERFIL DE JUGADOR
        return _buildPlayerProfile(player);
      },
    );
  }

  // --- VISTA PERFIL COMPLETO ---
  Widget _buildPlayerProfile(Map<String, dynamic> player) {
    String name = player['riotIdName'] ?? "Unknown";
    String tag = player['riotIdTag'] ?? "EUW";
    String region = player['region'] ?? "EUW";
    int level = player['summonerLevel'] ?? 1;
    String tier = player['tier'] ?? "UNRANKED"; // Ej: GOLD
    String division = player['division'] ?? ""; // Ej: IV
    int lp = player['leaguePoints'] ?? 0;

    // Obtenemos los estilos dinámicos
    Color rankColor = _getRankColor(tier);
    Gradient bgGradient = _getRankGradient(tier);
    String rankImgUrl = _getRankImageUrl(tier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // --- AVATAR Y CABECERA ---
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 3), // Borde cambia según rango
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[900],
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "$name #$tag",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$region • Nivel $level",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          // --- TARJETA DE RANGO DINÁMICA ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: bgGradient, // <--- DEGRADADO DINÁMICO
                border: Border.all(color: rankColor.withOpacity(0.5)), // <--- BORDE DINÁMICO
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                ]
            ),
            child: Row(
              children: [
                // IMAGEN DEL RANGO (Desde Internet)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.network(
                    rankImgUrl,
                    fit: BoxFit.contain,
                    // Si falla la carga (internet lento), mostramos un escudo por defecto
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.shield, size: 80, color: rankColor),
                  ),
                ),

                const SizedBox(width: 20),

                // TEXTOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CLASIFICATORIA FLEXIBLE", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
                      const SizedBox(height: 5),
                      Text(
                        tier,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: rankColor, // <--- TEXTO COLOR RANGO
                            fontStyle: FontStyle.italic
                        ),
                      ),
                      Text(
                        "$division • $lp LP",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- BOTONES (Sin cambios) ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _confirmUnlink(),
              icon: const Icon(Icons.link_off, color: Colors.red),
              label: const Text("DESVINCULAR RIOT ID", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.grey[800],
              ),
              onPressed: () {
                ApiService.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkAccountForm() {
    // 1. Controladores para los campos de texto
    final nameController = TextEditingController();
    final tagController = TextEditingController();
    final levelController = TextEditingController(text: "30");
    final lpController = TextEditingController(text: "0");
    final iconController = TextEditingController(text: "1");

    // 2. Variables para los Dropdowns (Listas desplegables)
    String selectedRegion = "EUW";
    String selectedTier = "SILVER";
    String selectedDivision = "IV";

    bool isLoading = false;

    // Usamos StatefulBuilder para que al cambiar un Dropdown se actualice solo el formulario
    return StatefulBuilder(
      builder: (context, setStateForm) {

        // Helper para estilos de input (para no repetir código)
        InputDecoration buildDecor(String label, IconData icon) {
          return InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1E2328),
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          );
        }

        // Helper para Dropdowns
        Widget buildDropdown(String label, String value, List<String> items, Function(String?) onChange) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF1E2328), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C3036),
                    style: const TextStyle(color: Colors.white),
                    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setStateForm(() => onChange(val)),
                  ),
                ),
              ),
            ],
          );
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFFC9AA71)),
                const SizedBox(height: 10),
                const Text("VINCULACIÓN MANUAL (DEV)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                const Text("Introduce datos falsos para pruebas", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 25),

                // --- FILA 1: NOMBRE Y TAG ---
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: buildDecor("Riot ID", Icons.person))),
                    const SizedBox(width: 10),
                    Expanded(flex: 1, child: TextField(controller: tagController, style: const TextStyle(color: Colors.white), decoration: buildDecor("TAG", Icons.tag))),
                  ],
                ),
                const SizedBox(height: 15),

                // --- FILA 2: REGIÓN Y NIVEL ---
                Row(
                  children: [
                    Expanded(child: buildDropdown("Región", selectedRegion, ["EUW", "NA", "KR"], (v) => selectedRegion = v!)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: levelController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: buildDecor("Nivel", Icons.bar_chart))),
                  ],
                ),
                const SizedBox(height: 15),

                // --- FILA 3: TIER Y DIVISIÓN ---
                Row(
                  children: [
                    Expanded(flex: 3, child: buildDropdown("Liga", selectedTier, ["IRON", "BRONZE", "SILVER", "GOLD", "PLATINUM", "EMERALD", "DIAMOND", "MASTER", "GRANDMASTER", "CHALLENGER"], (v) => selectedTier = v!)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: buildDropdown("División", selectedDivision, ["I", "II", "III", "IV"], (v) => selectedDivision = v!)),
                  ],
                ),
                const SizedBox(height: 15),

                // --- FILA 4: LP E ICONO ---
                Row(
                  children: [
                    Expanded(child: TextField(controller: lpController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: buildDecor("LPs", Icons.numbers))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: iconController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: buildDecor("Icon ID", Icons.image))),
                  ],
                ),
                const SizedBox(height: 30),

                // --- BOTÓN DE GUARDAR ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.isEmpty || tagController.text.isEmpty) return;

                      setStateForm(() => isLoading = true);

                      // 1. Preparamos el JSON Manual
                      final manualData = {
                        "gameName": nameController.text,
                        "tagLine": tagController.text,
                        "region": selectedRegion,
                        "summonerLevel": int.tryParse(levelController.text) ?? 30,
                        "tier": selectedTier,
                        "division": selectedDivision,
                        "leaguePoints": int.tryParse(lpController.text) ?? 0,
                        "profileIconId": int.tryParse(iconController.text) ?? 1,
                      };

                      // 2. Llamamos al endpoint nuevo (linkManualAccount)
                      bool success = await ApiService.createDevPlayer(manualData);

                      if (success) {
                        _refreshProfile(); // Recarga la pantalla principal
                      } else {
                        setStateForm(() => isLoading = false);
                        if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar datos manuales."))
                          );
                        }
                      }
                    },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("GUARDAR PERFIL MANUAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón Logout
                TextButton.icon(
                  onPressed: () async {
                    await ApiService.logout();
                    if(mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
                    }
                  },
                  icon: const Icon(Icons.logout, size: 16, color: Colors.grey),
                  label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmUnlink() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        title: const Text("¿Desvincular cuenta?"),
        content: const Text("Perderás tu rango y saldrás de tu equipo actual. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              bool success = await ApiService.unlinkRiotAccount();
              if (success) {
                _refreshProfile(); // Volver al formulario
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cuenta desvinculada.")));
              }
            },
            child: const Text("Desvincular", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getRankImageUrl(String tier) {
    // Convertimos a minúsculas porque la URL lo requiere (gold, diamond, etc.)
    String t = tier.toLowerCase();
    if (t == 'unranked') {
      return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblems/unranked.png";
    }
    // URL oficial de CommunityDragon
    return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblems/emblem-$t.png";
  }

  // 2. Obtener el color principal (para textos o bordes)
  Color _getRankColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'IRON': return const Color(0xFF655D58);
      case 'BRONZE': return const Color(0xFF8C523A);
      case 'SILVER': return const Color(0xFF8E9DA4);
      case 'GOLD': return const Color(0xFFE3B24F);
      case 'PLATINUM': return const Color(0xFF259893);
      case 'EMERALD': return const Color(0xFF27A845);
      case 'DIAMOND': return const Color(0xFF5378AD);
      case 'MASTER': return const Color(0xFF9D5DD3);
      case 'GRANDMASTER': return const Color(0xFFCD3744);
      case 'CHALLENGER': return const Color(0xFFF4C874); // Dorado brillante
      default: return Colors.grey;
    }
  }

  // 3. Obtener el degradado de fondo para la tarjeta
  Gradient _getRankGradient(String tier) {
    Color base = _getRankColor(tier);
    return LinearGradient(
      colors: [
        const Color(0xFF1E2328), // Fondo oscuro base
        base.withOpacity(0.25),  // Color del rango sutil
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}

// ==========================================
// PANTALLA DE LOGIN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController(); // Confirmar contraseña
  bool _isLoading = false;

  void _handleRegister() async {
    // 1. Validaciones básicas
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Por favor, rellena todos los campos");
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      _showError("Las contraseñas no coinciden");
      return;
    }

    setState(() => _isLoading = true);

    // 2. Llamada a la API (Por defecto registramos como 'USER')
    // El ApiService que hicimos ya guarda el token automáticamente si el registro es 200 OK
    bool success = await ApiService.register(
        _emailController.text,
        _passController.text,
        "USER"
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // 3. Éxito: Vamos directo a la App principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false, // Elimina el historial de navegación anterior
      );
    } else if (mounted) {
      _showError("Error al registrarse. El email podría estar en uso.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el mismo fondo degradado
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, const Color(0xFF1E2328)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView( // Para evitar error de pixel overflow al sacar teclado
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Color(0xFFD32F2F)),
                const SizedBox(height: 20),
                const Text("NUEVA LEYENDA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text("Únete a la competición", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // Campos
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPassController,
                  decoration: const InputDecoration(labelText: 'Confirmar Contraseña', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),

                const SizedBox(height: 30),

                // Botón Registro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("CREAR CUENTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Botón Volver al Login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Vuelve atrás
                  },
                  child: const Text("¿Ya tienes cuenta? Inicia Sesión", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    // ApiService.login ahora guarda internamente los tokens en SecureStorage
    bool success = await ApiService.login(_emailController.text, _passController.text);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen())
      );
    }else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Credenciales incorrectas'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, const Color(0xFF1E2328)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 80, color: Color(0xFFD32F2F)),
            const SizedBox(height: 20),
            const Text("LEGENDS ID", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("INICIAR SESIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () {
                // AHORA SÍ navegamos a la pantalla de registro
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen())
                );
              },
              child: const Text("¿No tienes cuenta? Regístrate", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TournamentView(), // CONECTADA A API
    TeamView(),       // <--- AQUÍ estaba el "Próximamente", cámbialo por TeamView()
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.shield, color: Color(0xFFD32F2F)),
            const SizedBox(width: 8),
            Text('LEGENDS CUP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.9))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ApiService.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF090A0C),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Torneos'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Mi Equipo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<dynamic>> _allTeamsFuture;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _profileFuture = ApiService.getMe();
      _allTeamsFuture = ApiService.getAllTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // Carga inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
        }

        final user = snapshot.data;

        // CASO 1: NO TIENE JUGADOR ASOCIADO
        // Si user es null o user['player'] es null
        if (user == null || user['player'] == null) {
          return _buildNoPlayerWarning();
        }

        final player = user['player'];
        final team = player['team'];

        // CASO 2: TIENE JUGADOR Y TIENE EQUIPO
        if (team != null) {
          return _buildMyTeamDetails(team, player['id']); // Pasamos mi ID para saber si soy líder
        }

        // CASO 3: TIENE JUGADOR PERO NO EQUIPO (BUSCADOR)
        return _buildTeamFinder();
      },
    );
  }

  // --- WIDGET CASO 1: SIN CUENTA VINCULADA ---
  Widget _buildNoPlayerWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Falta vincular cuenta",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ve a tu perfil y vincula tu cuenta de Riot para poder acceder a los equipos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
              ),
              onPressed: () {
                // Aquí podrías redirigir al Tab de Perfil programáticamente
                // O simplemente decirle al usuario que vaya él.
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ve a la pestaña 'Perfil' en el menú inferior"))
                );
              },
              child: const Text("IR A MI PERFIL", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET CASO 2: MI EQUIPO (DETALLES E INTEGRANTES) ---
  Widget _buildMyTeamDetails(Map<String, dynamic> team, int myPlayerId) {
    // Si la lista de miembros no viene cargada por el @JsonIgnoreProperties del Player,
    // hacemos una llamada extra o confiamos en que el backend ahora (con los cambios en Team.java)
    // nos envíe los miembros cuando consultamos el equipo.
    // Asumiremos que al hacer /users/me -> player -> team, el team trae 'members' gracias a quitar el @JsonIgnore.

    List<dynamic> members = team['members'] ?? [];
    bool amILeader = team['leader'] != null && team['leader']['id'] == myPlayerId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Cabecera Equipo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2328),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC9AA71)), // Borde Dorado
            ),
            child: Column(
              children: [
                const Icon(Icons.shield, size: 60, color: Color(0xFFD32F2F)),
                const SizedBox(height: 10),
                Text(team['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text("Tag: [${team['tag']}]", style: const TextStyle(fontSize: 18, color: Color(0xFFC9AA71), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoBadge("Región", team['region'] ?? "EUW"),
                    const SizedBox(width: 10),
                    _buildInfoBadge("División", team['division'] ?? "IV"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("ROSTER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5))),
          const SizedBox(height: 10),

          // Lista de Integrantes
          ListView.builder(
            shrinkWrap: true, // Importante dentro de SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              bool isLeader = m['leader'] == true;

              return Card(
                color: const Color(0xFF1E2328),
                margin: const EdgeInsets.symmetric(vertical: 4), // Un poco de separación
                child: ListTile(
                  // --- CAMBIO AQUÍ: USAMOS EL COLOR DINÁMICO ---
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _getRankColor(m['tier']), // Borde del color del rango
                          width: 2
                      ),
                    ),
                    child: Center(
                      child: Text(
                        m['riotIdName'] != null ? m['riotIdName'].substring(0, 1).toUpperCase() : "?",
                        style: TextStyle(
                            color: _getRankColor(m['tier']), // Letra del color del rango
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                  // ---------------------------------------------

                  title: Text(
                      "${m['riotIdName']}#${m['riotIdTag']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  subtitle: Text(
                    "${m['tier'] ?? 'UNRANKED'} ${m['rank'] ?? ''} ${m['division'] ?? ''}", // Ojo: a veces viene 'rank' o 'division' según tu DTO
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  trailing: isLeader
                      ? const Tooltip(
                    message: "Líder",
                    child: Text("👑", style: TextStyle(fontSize: 24)), // Corona dorada
                  )
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Botones de acción
          if (amILeader)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text("DISOLVER EQUIPO", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // Implementar lógica de borrar equipo
                await ApiService.leaveTeam(); // O endpoint específico deleteTeam
                _refreshData();
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text("ABANDONAR EQUIPO", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await ApiService.leaveTeam();
                _refreshData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3))
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // --- WIDGET CASO 3: BUSCADOR DE EQUIPOS (FILTRO NO LLENOS) ---
  Widget _buildTeamFinder() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Buscar equipo...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1E2328),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        // Cabecera lista
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text("EQUIPOS RECLUTANDO (Huecos disponibles)", style: TextStyle(color: Color(0xFFC9AA71), fontSize: 12))
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allTeamsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No hay equipos disponibles. ¡Crea uno!"));

              // LOGICA DE FILTRADO
              final teams = snapshot.data!.where((t) {
                final nameMatch = t['name'].toString().toLowerCase().contains(_searchQuery);

                // Comprobamos si está lleno.
                // Como modificamos Team.java para incluir 'members', podemos ver el length.
                List members = t['members'] ?? [];
                final isNotFull = members.length < 5;

                return nameMatch && isNotFull;
              }).toList();

              if (teams.isEmpty) return const Center(child: Text("No se encontraron equipos con huecos libres."));

              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final t = teams[index];
                  List members = t['members'] ?? [];

                  return Card(
                    color: const Color(0xFF1E2328),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.shield_outlined, color: Colors.white),
                      title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Región: ${t['region']} • Miembros: ${members.length}/5"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9AA71)),
                        onPressed: () async {
                          bool success = await ApiService.joinTeam(t['id']);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Te has unido al equipo")));
                            _refreshData(); // Recargamos para que ahora salga la vista "Mi Equipo"
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al unirse")));
                          }
                        },
                        child: const Text("UNIRSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Botón Crear Equipo
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), padding: const EdgeInsets.all(16)),
              onPressed: () => _showCreateTeamDialog(context),
              child: const Text("CREAR NUEVO EQUIPO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    // (Mantener el código del diálogo de creación que te pasé antes)
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    // ... (Resto del showDialog)
    // Asegúrate de llamar a _refreshData() al terminar de crear.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        title: const Text("Crear Equipo", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Nombre del Equipo",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F)))
                )
            ),
            TextField(
                controller: tagCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Tag (3 letras)",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F)))
                )
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              // 1. Validación Previa
              if (nameCtrl.text.isEmpty || tagCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rellena todos los campos"), backgroundColor: Colors.orange)
                );
                return;
              }

              // 2. Llamada al Backend
              bool success = await ApiService.createTeam(nameCtrl.text, tagCtrl.text, "EUW");

              // 3. Lógica de Respuesta
              if (success) {
                // SI FUE BIEN: Cerramos diálogo, recargamos y mensaje verde
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Equipo creado!"), backgroundColor: Colors.green)
                );
              } else {
                // SI FALLÓ: NO cerramos el diálogo para que el usuario corrija
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: Nombre duplicado o servidor caído"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("Crear", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Color _getRankColor(String? tier) {
    if (tier == null) return Colors.grey;
    switch (tier.toUpperCase()) {
      case 'IRON': return const Color(0xFF655D58);
      case 'BRONZE': return const Color(0xFF8C523A);
      case 'SILVER': return const Color(0xFF8E9DA4);
      case 'GOLD': return const Color(0xFFE3B24F);
      case 'PLATINUM': return const Color(0xFF259893);
      case 'EMERALD': return const Color(0xFF27A845);
      case 'DIAMOND': return const Color(0xFF5378AD);
      case 'MASTER': return const Color(0xFF9D5DD3);
      case 'GRANDMASTER': return const Color(0xFFCD3744);
      case 'CHALLENGER': return const Color(0xFFF4C874);
      default: return Colors.grey;
    }
  }
}


// ==========================================
// VISTA DE TORNEOS (CONECTADA)
// ==========================================
class TournamentView extends StatefulWidget {
  const TournamentView({super.key});

  @override
  State<TournamentView> createState() => _TournamentViewState();
}

class _TournamentViewState extends State<TournamentView> {
  late Future<List<dynamic>> _historyFuture;
  late Future<List<dynamic>> _tournamentsFuture;

  // Para el ejemplo, buscamos partidos del torneo ID 1.
  // En prod, deberías buscar el primer torneo activo de la lista.
  late Future<List<dynamic>> _liveMatchesFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getHistory("EUW");
    _tournamentsFuture = ApiService.getTournaments();
    _liveMatchesFuture = ApiService.getCurrentMatches(1);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MATCHES EN VIVO
          const SectionHeader(title: "EN JUEGO AHORA"),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: _liveMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(color: Color(0xFFD32F2F));
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF1E2328),
                  child: const Center(child: Text("No hay partidos en vivo en el Torneo #1", style: TextStyle(color: Colors.grey))),
                );
              }
              // Mostramos solo el primer partido encontrado
              var match = snapshot.data![0];
              return _buildLiveMatchCard(match);
            },
          ),

          const SizedBox(height: 30),

          // 2. HISTORIAL
          const SectionHeader(title: "HALL OF FAME (EUW)"),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Sin historial");

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];
                    return _buildHistoryCard(
                      item['tournamentName'] ?? 'Torneo',
                      item['winnerName'] ?? 'Desconocido',
                      item['fechaInicio'] != null ? DateFormat('MMM yyyy').format(DateTime.parse(item['fechaInicio'])) : '-',
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 3. LISTA DE TORNEOS
          const SectionHeader(title: "INSCRIPCIONES ABIERTAS"),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: _tournamentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) return const Text("Error cargando torneos");

              return Column(
                children: snapshot.data!.map((t) => _buildTournamentRow(
                  t['name'],
                  t['region'],
                  t['status'],
                  "${t['currentRound'] ?? 0} Rondas", // Puedes cambiar esto por MaxTeams si lo traes
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Con Datos Reales) ---

  Widget _buildLiveMatchCard(dynamic match) {
    // Extraemos nombres de forma segura
    String teamA = match['teamA'] != null ? match['teamA']['name'] : 'TBD';
    String teamB = match['teamB'] != null ? match['teamB']['name'] : 'TBD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2328),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.5)),
        boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text("RONDA ${match['round']}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamLogo(teamA, false),
              const Text("VS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9AA71))),
              _buildTeamLogo(teamB, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name, bool isWinner) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: isWinner ? const Color(0xFFC9AA71) : Colors.grey, width: 2),
          ),
          child: Center(child: Text(name.isNotEmpty ? name.substring(0, 1) : "?", style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryCard(String tournament, String winner, String date) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF2A2E35), Colors.black.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC9AA71).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFC9AA71), size: 30),
          const SizedBox(height: 8),
          Text(winner, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          Text(tournament, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFFD32F2F))),
        ],
      ),
    );
  }

  Widget _buildTournamentRow(String name, String region, String status, String info) {
    Color statusColor = status == "ABIERTO" ? Colors.green : (status == "FINALIZADO" ? Colors.grey : Colors.red);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2328), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: const Color(0xFFD32F2F)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(children: [
                  Text(region, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(width: 8),
                  Text(info, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0));
  }
}