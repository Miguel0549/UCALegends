import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'api_service.dart'; // Importa el archivo que creamos arriba
import 'splash_screen.dart';
import 'HallOfFame.dart';
import 'TournamentDeatailScreen.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. REUTILIZAMOS LA TARJETA VISUAL
          PlayerInfoCard(player: player),

          const SizedBox(height: 40),

          // 2. AÑADIMOS LOS BOTONES DE GESTIÓN (Solo para ti)
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
          return _buildMyTeamDetails(team, player['id'],() => _refreshData()); // Pasamos mi ID para saber si soy líder
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
  Widget _buildMyTeamDetails(Map<String, dynamic> team, int myPlayerId, VoidCallback onRefresh, {bool isReadOnly = false}) {

    int teamId = team['id'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Si es un modal, ponemos una rayita arriba para indicar que se puede bajar
          if (isReadOnly)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
            ),

          // --- 1. CABECERA (Siempre visible) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2328),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC9AA71)),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield, size: 60, color: Color(0xFFD32F2F)),
                const SizedBox(height: 10),
                Text(team['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
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

          const SizedBox(height: 20),

          // --- 2. CARGA DE MIEMBROS ---
          FutureBuilder<List<dynamic>>(
            future: ApiService.getTeamMembers(teamId),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFC9AA71)));
              }
              if (snapshot.hasError) return const Text("Error cargando roster", style: TextStyle(color: Colors.red));

              final members = snapshot.data ?? [];

              // Calculamos liderazgo (SOLO si NO es modo lectura, ahorramos lógica)
              bool amILeader = false;
              if (!isReadOnly) {
                try {
                  final meInTeam = members.firstWhere((m) => m['id'] == myPlayerId, orElse: () => null);
                  if (meInTeam != null) {
                    amILeader = meInTeam['leader'] == true || meInTeam['isLeader'] == true;
                  }
                } catch (e) { print(e); }
              }

              return Column(
                children: [

                  // --- BOTÓN GESTIÓN (Solo si soy líder Y NO es modo lectura) ---
                  if (amILeader && !isReadOnly)
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC9AA71),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text("GESTIONAR SOLICITUDES", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showRequestsSheet(context,onRefresh),
                      ),
                    ),

                  const Align(alignment: Alignment.centerLeft, child: Text("ROSTER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5))),
                  const SizedBox(height: 10),

                  if (members.isEmpty) const Text("No hay miembros visibles.", style: TextStyle(color: Colors.white)),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final m = members[index];
                      bool isThisMemberLeader = m['leader'] == true || m['isLeader'] == true;
                      bool isMe = m['id'] == myPlayerId;

                      // Solo mostramos acciones si NO es lectura, SOY líder y NO soy yo mismo
                      bool showAdminActions = !isReadOnly && amILeader && !isMe;

                      return Card(
                        color: const Color(0xFF1E2328),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _getRankColor(m['tier'] ?? 'UNRANKED'), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                (m['riotIdName'] ?? "?").substring(0, 1).toUpperCase(),
                                style: TextStyle(color: _getRankColor(m['tier'] ?? 'UNRANKED'), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          title: Text("${m['riotIdName']} #${m['riotIdTag']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text("${m['tier'] ?? 'UNRANKED'} ${m['division'] ?? ''}", style: TextStyle(color: Colors.grey[400], fontSize: 12)),

                          trailing: isThisMemberLeader
                              ? const Tooltip(message: "Líder", child: Text("👑", style: TextStyle(fontSize: 24)))
                              : (showAdminActions
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.star_outline, color: Colors.yellow),
                                onPressed: () => _showTransferConfirmation(context, m, onRefresh),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_remove, color: Color(0xFFD32F2F)),
                                onPressed: () => _showKickConfirmation(context, m,onRefresh),
                              ),
                            ],
                          )
                              : null), // Si es ReadOnly, el trailing será null (o la corona si es líder)
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- BOTONES DE SALIDA (Solo si NO es modo lectura) ---
                  if (!isReadOnly) ...[
                    if (amILeader)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        label: const Text("DISOLVER EQUIPO", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          // Confirmación básica
                          bool confirm = await showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("¿Disolver equipo?"),
                                content: const Text("Todos los miembros serán expulsados. Esto no se puede deshacer."),
                                actions: [
                                  TextButton(onPressed:()=>Navigator.pop(c, false), child: const Text("Cancelar")),
                                  TextButton(onPressed:()=>Navigator.pop(c, true), child: const Text("Disolver", style: TextStyle(color: Colors.red))),
                                ],
                              )
                          ) ?? false;

                          if (confirm) {
                            bool success = await ApiService.dissolveTeam();
                            if (success) {
                              onRefresh(); // <--- RECARGA LA PANTALLA
                            }
                          }
                        },
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                        icon: const Icon(Icons.exit_to_app, color: Colors.white),
                        label: const Text("ABANDONAR EQUIPO", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          bool confirm = await showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("¿Abandonar equipo?"),
                                actions: [
                                  TextButton(onPressed:()=>Navigator.pop(c, false), child: const Text("Cancelar")),
                                  TextButton(onPressed:()=>Navigator.pop(c, true), child: const Text("Salir", style: TextStyle(color: Colors.red))),
                                ],
                              )
                          ) ?? false;

                          if (confirm) {
                            bool success = await ApiService.leaveTeam();
                            if (success) {
                              onRefresh(); // <--- RECARGA LA PANTALLA
                            }
                          }
                        },
                      ),
                  ] else ...[
                    // Si es modo lectura, quizás quieras poner un botón de cerrar o nada
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cerrar", style: TextStyle(color: Colors.grey)),
                    )
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }

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
      case 'CHALLENGER': return const Color(0xFFF4C874);
      default: return Colors.grey;
    }
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

              // En tu lista de equipos disponibles:

              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];

                  return Card(
                    // ... tu decoración ...
                    child: ListTile(
                      title: Text(team['name']),
                      subtitle: Text("Miembros: ${team['members']?.length ?? '?'}/5"), // O lo que tengas
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9AA71)),
                        onPressed: () async {
                          bool success = await ApiService.requestJoinTeam(team['id']);
                          if (success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ Solicitud enviada al líder"),
                                    backgroundColor: Colors.green,
                                  )
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Error: Ya has solicitado o tienes equipo"),
                                    backgroundColor: Colors.red,
                                  )
                              );
                            }
                          }
                        },
                        child: const Text("SOLICITAR UNIRSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),

                      // --- AQUÍ AÑADIMOS EL EVENTO AL TOCAR EL EQUIPO ---
                      onTap: () {
                        // Mostramos los detalles en una hoja deslizante (BottomSheet)
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // Para que pueda ocupar más pantalla si es necesario
                          backgroundColor: const Color(0xFF090A0C),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.7, // Altura inicial (70% de la pantalla)
                              minChildSize: 0.4,
                              maxChildSize: 0.95,
                              expand: false,
                              builder: (context, scrollController) {
                                // Reutilizamos la función con isReadOnly: true
                                return SingleChildScrollView(
                                  controller: scrollController,
                                  // Pasamos una función vacía () {} en onRefresh porque en modo lectura no vamos a refrescar nada
                                  child: _buildMyTeamDetails(team, 0, () {}, isReadOnly: true),
                                );
                              },
                            );
                          },
                        );
                      },
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

  Future<void> _showTransferConfirmation(BuildContext context, Map<String, dynamic> member, VoidCallback onRefresh) async {
    bool confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        title: const Text("👑 Transferir Liderazgo", style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Estás seguro de nombrar líder a ${member['riotIdName']}?\n\nDejarás de ser el líder y perderás los permisos de gestión inmediatamente.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("CONFIRMAR", style: TextStyle(color: Color(0xFFC9AA71), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // 1. Llamar a la API
      bool success = await ApiService.transferLeadership(member['id']);

      if (success) {
        // 2. Feedback visual
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ahora ${member['riotIdName']} es el líder del equipo.")),
          );
        }
        // 3. RECARGAR (Muy importante: ya no verás los botones de admin)
        onRefresh();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al transferir liderazgo.")),
          );
        }
      }
    }
  }

  void _showKickConfirmation(BuildContext context, Map<String, dynamic> member,VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2328),
          title: const Text("¿Expulsar jugador?", style: TextStyle(color: Colors.white)),
          content: Text(
            "¿Estás seguro de que quieres eliminar a ${member['riotIdName']} del equipo? Esta acción no se puede deshacer.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              child: const Text("EXPULSAR", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Cerrar diálogo

                // 1. Llamar a la API
                // Asegúrate de que member['id'] es el ID del Player, no del User
                bool success = await ApiService.kickMember(member['id']);

                if (success) {
                  // 2. Refrescar la pantalla
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${member['riotIdName']} ha sido expulsado."))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error al expulsar al jugador."))
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRequestsSheet(BuildContext context,VoidCallback onRefresh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2328),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getTeamRequests(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final reqs = snapshot.data!;

            if (reqs.isEmpty) return const Center(child: Text("No hay solicitudes pendientes", style: TextStyle(color: Colors.white)));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reqs.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final req = reqs[index];
                return ListTile(
                  title: Text("${req['player']['riotIdName']}#${req['player']['riotIdTag']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Nivel: ${req['player']['summonerLevel']}", style: const TextStyle(color: Colors.grey)),

                  // CLICK PARA VER PERFIL
                  onTap: () {
                    if (req['player']['id'] != null) {
                      int id = req['player']['id']; // Si viene como int
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileView(playerId: id),
                        ),
                      );
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RECHAZAR
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await ApiService.respondRequest(req['requestId'], false);
                          Navigator.pop(context);
                          onRefresh();// Cierra y obliga a reabrir o usa setState
                        },
                      ),
                      // ACEPTAR
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await ApiService.respondRequest(req['requestId'], true);
                          Navigator.pop(context); // Cierra para refrescar la vista del equipo detrás
                          onRefresh();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
}

class UserProfileView extends StatefulWidget {
  final int playerId;

  const UserProfileView({super.key, required this.playerId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    // Llamada a la API buscando por ID
    _userFuture = ApiService.getProfileUser(widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091428),
      appBar: AppBar(
        title: const Text("Perfil de Invocador"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC9AA71)));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Perfil no encontrado o privado", style: TextStyle(color: Colors.white)));
          }

          // Aquí reutilizamos el widget visual
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: PlayerInfoCard(player: snapshot.data!),
          );
        },
      ),
    );
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

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _historyFuture = ApiService.getHistory("EUW");
    _tournamentsFuture = ApiService.getTournaments();
    _liveMatchesFuture = ApiService.getCurrentMatches(1);
  }

  void _checkAdminRole() async {
    bool admin = await ApiService.isUserAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  void _showCreateTournamentDialog() {
    // Controladores y valores por defecto
    final nameController = TextEditingController();
    String selectedRegion = "EUW";
    String selectedGameMode = "CLASSIC"; // O "ARAM", "5v5"
    int selectedMaxTeams = 8; // Mejor usar potencias de 2 (4, 8, 16)

    // Fechas por defecto
    DateTime dateInsc = DateTime.now().add(const Duration(days: 2));
    DateTime dateInicio = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Necesario para que los Dropdowns y Fechas cambien visualmente
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2328),
              title: const Text("Crear Nuevo Torneo", style: TextStyle(color: Color(0xFFC9AA71))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. NOMBRE
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Nombre del Torneo",
                        labelStyle: TextStyle(color: Colors.grey),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC9AA71))),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 2. REGIÓN Y MODO DE JUEGO (Fila)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedRegion,
                            dropdownColor: const Color(0xFF1E2328),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "Región", labelStyle: TextStyle(color: Colors.grey)),
                            items: ["EUW", "NA", "KR", "LATAM"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (val) => setDialogState(() => selectedRegion = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGameMode,
                            dropdownColor: const Color(0xFF1E2328),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "Modo", labelStyle: TextStyle(color: Colors.grey)),
                            items: ["CLASSIC", "ARAM", "1v1"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setDialogState(() => selectedGameMode = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 3. MAX EQUIPOS
                    DropdownButtonFormField<int>(
                      value: selectedMaxTeams,
                      dropdownColor: const Color(0xFF1E2328),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Máx. Equipos", labelStyle: TextStyle(color: Colors.grey)),
                      items: [4, 8, 16, 32].map((n) => DropdownMenuItem(value: n, child: Text("$n Equipos"))).toList(),
                      onChanged: (val) => setDialogState(() => selectedMaxTeams = val!),
                    ),
                    const SizedBox(height: 20),

                    // 4. FECHAS (Selectores)
                    _buildDatePicker(
                        "Cierre Inscripciones",
                        dateInsc,
                            (newDate) => setDialogState(() => dateInsc = newDate)
                    ),
                    const SizedBox(height: 10),
                    _buildDatePicker(
                        "Inicio Torneo",
                        dateInicio,
                            (newDate) => setDialogState(() => dateInicio = newDate)
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9AA71)),
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    // Validación simple de fechas
                    if (dateInicio.isBefore(dateInsc)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("El torneo no puede empezar antes del cierre de inscripciones"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(context); // Cerrar modal

                    bool success = await ApiService.createTournament(
                      name: nameController.text,
                      region: selectedRegion,
                      gameMode: selectedGameMode,
                      maxTeams: selectedMaxTeams,
                      fechaInscripciones: dateInsc,
                      fechaInicio: dateInicio,
                    );

                    if (success) {
                      _refreshData(); // <--- Recargar la lista de torneos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Torneo creado con éxito"), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al crear torneo"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text("CREAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDatePicker(String label, DateTime currentDate, Function(DateTime) onSelect) {

    // Formateamos para que los minutos tengan siempre 2 dígitos (ej: 05, 00, 15)
    String minuteStr = currentDate.minute.toString().padLeft(2, '0');
    String hourStr = currentDate.hour.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFFC9AA71)),
          label: Text(
            // AQUÍ ESTABA EL ERROR: Ahora usamos las variables reales
            "${currentDate.day}/${currentDate.month}  $hourStr:$minuteStr",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            // 1. Elegir Día
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: currentDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFC9AA71), // Color del selector
                      onPrimary: Colors.black,    // Color texto seleccionado
                      surface: Color(0xFF1E2328), // Fondo calendario
                    ),
                  ),
                  child: child!
              ),
            );

            if (pickedDate == null) return;

            // 2. Elegir Hora (Necesario si no el widget se desmonta)
            if (!mounted) return;

            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(currentDate),
              builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFC9AA71),
                      onPrimary: Colors.black,
                      surface: Color(0xFF1E2328),
                    ),
                  ),
                  child: child!
              ),
            );

            // 3. Combinar Fecha + Hora
            if (pickedTime != null) {
              // Creamos un nuevo DateTime con el día elegido y la hora elegida
              final newDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute
              );
              onSelect(newDateTime);
            } else {
              // Si cancela la hora, guardamos al menos la fecha con hora 00:00
              onSelect(DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  currentDate.hour,   // Mantenemos la hora que tenía antes
                  currentDate.minute
              ));
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --- 1. PARTIDO DESTACADO (LIVE) ---
          // (Esto lo mantenemos fuera del filtro de torneos porque va por su propia API de matches)
          const SectionHeader(title: "PARTIDO DESTACADO"),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: _liveMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(color: Color(0xFFC9AA71));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.tv_off, color: Colors.grey),
                      SizedBox(width: 10),
                      Text("No hay partidos en directo.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return _buildLiveMatchCard(snapshot.data![0]);
            },
          ),

          const SizedBox(height: 30),

          // ============================================================
          //    CARGA DE TODOS LOS TORNEOS (DIVISIÓN EN 3 LISTAS)
          // ============================================================
          FutureBuilder<List<dynamic>>(
            future: _tournamentsFuture,
            builder: (context, snapshot) {

              // A. ESTADO DE CARGA
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFC9AA71)));
              }

              // B. ESTADO SIN DATOS
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No hay información de torneos.", style: TextStyle(color: Colors.grey));
              }

              // C. FILTRADO DE LISTAS
              final allList = snapshot.data!;

              // 1. EN CURSO
              final activeTournaments = allList.where((t) => t['status'] == 'EN_CURSO').toList();

              // 2. FINALIZADOS (Hall of Fame)
              final finishedTournaments = allList.where((t) => t['status'] == 'FINALIZADO').toList();

              // 3. ABIERTOS (Inscripciones)
              final openTournaments = allList.where((t) => t['status'] == 'ABIERTO' || t['status'] == 'CERRADO').toList();


              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // -----------------------------------------------------
                  // SECCIÓN 1: TORNEOS EN CURSO
                  // -----------------------------------------------------
                  if (activeTournaments.isNotEmpty) ...[
                    const SectionHeader(title: "🏆 EN JUEGO"),
                    const SizedBox(height: 10),
                    ...activeTournaments.map((t) => _buildTournamentRow(
                      t['name'],
                      t['region'],
                      t['status'],
                      "Ronda ${t['currentRound'] ?? 1}",
                    )),
                    const SizedBox(height: 30),
                  ],

                  // -----------------------------------------------------
                  // SECCIÓN 2: HALL OF FAME (Finalizados)
                  // -----------------------------------------------------
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(title: "🏛️ HALL OF FAME"),
                      // Opcional: Icon(Icons.history, color: Color(0xFFC9AA71)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (finishedTournaments.isEmpty)
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Text("Aún no hay campeones coronados.", style: TextStyle(color: Colors.grey))
                    )
                  else
                    SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: finishedTournaments.length,
                        itemBuilder: (context, index) {
                          final t = finishedTournaments[index];

                          // ADAPTADOR DE DATOS:
                          // La lista general trae el objeto 'winner' entero (JSON),
                          // pero la tarjeta espera 'winnerName' (String). Lo mapeamos aquí:
                          Map<String, dynamic> cardData = {
                            'tournamentName': t['name'],
                            'region': t['region'],
                            'fechaInicio': t['fechaInicio'],
                            // Accedemos a ['winner']['name'] con seguridad
                            'winnerName': (t['winner'] != null && t['winner']['name'] != null)
                                ? t['winner']['name']
                                : 'Desconocido'
                          };

                          return Container(
                            width: 320,
                            margin: const EdgeInsets.only(right: 12),
                            child: HallOfFameCard(tournament: cardData),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 30),

                  // -----------------------------------------------------
                  // SECCIÓN 3: INSCRIPCIONES ABIERTAS
                  // -----------------------------------------------------
                  const SectionHeader(title: "✍️ INSCRIPCIONES"),
                  const SizedBox(height: 10),

                  if (openTournaments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      child: const Text("No hay inscripciones ahora mismo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)
                      ),
                    )
                  else
                    ...openTournaments.map((t) {
                      final String infoText = (t['status'] == 'ABIERTO')
                          ? "Inscripción ABIERTA hasta ${t['fechaInscripciones'].toString().replaceAll('T', ' ').substring(0, 16)}"
                          : "Inicio Torneo : ${t['fechaInicio'].toString().replaceAll('T', ' ').substring(0, 16)}";

                      // 2. Retornamos la fila con los datos procesados
                      return _buildTournamentRow(
                        t['name'],
                        t['region'],
                        t['status'],
                        infoText,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailScreen(tournamentId: t['id']),
                            ),
                          );
                        },
                      );
                    }),
                ],
              );
            },
          ),

          const SizedBox(height: 80),

          const SizedBox(height: 40),

          // --- BOTÓN SOLO VISIBLE PARA EL ADMIN ---
          if (_isAdmin)
            Center(
              child: Container(
                width: double.infinity,
                height: 55,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2328),
                    foregroundColor: const Color(0xFFC9AA71),
                    side: const BorderSide(color: Color(0xFFC9AA71), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 5,
                  ),
                  onPressed: _showCreateTournamentDialog,
                  icon: const Icon(Icons.add_moderator),
                  label: const Text(
                    "ADMIN PANEL: CREAR TORNEO",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
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

  // 1. Añade el parámetro onTap a la función
  Widget _buildTournamentRow(String name, String region, String status, String info, {VoidCallback? onTap}) {

    Color statusColor = status == 'ABIERTO' ? Colors.green : Colors.orange;

    // 2. Enuelve el Container en un InkWell
    return InkWell(
      onTap: onTap, // Se ejecuta la función al pulsar
      borderRadius: BorderRadius.circular(4), // Para que el efecto visual coincida con el borde
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: const Border(
            left: BorderSide(
              color: Color(0xFFD32F2F),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 4),
                  Text(region,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)
                  ),
                  const SizedBox(height: 4),
                  Text(info,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _historyFuture = ApiService.getHistory("EUW");
      _tournamentsFuture = ApiService.getTournaments();
      _liveMatchesFuture = ApiService.getCurrentMatches(1);
    });
  }
}

class PlayerInfoCard extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerInfoCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    String name = player['riotIdName'] ?? "Unknown";
    String tag = player['riotIdTag'] ?? "EUW";
    String region = player['region'] ?? "EUW";
    int level = player['summonerLevel'] ?? 1;
    String tier = player['tier'] ?? "UNRANKED";
    String division = player['division'] ?? "";
    int lp = player['leaguePoints'] ?? 0;
    int iconId = player['profileIconId'] ?? 1;

    Color rankColor = _getRankColor(tier);
    Gradient bgGradient = _getRankGradient(tier);
    String rankImgUrl = _getRankImageUrl(tier);

    return Column(
      children: [
        // --- AVATAR ---
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: 3),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage("https://ddragon.leagueoflegends.com/cdn/14.1.1/img/profileicon/$iconId.png"),
            backgroundColor: Colors.grey[900],
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

        // --- TARJETA DE RANGO ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: bgGradient,
              border: Border.all(color: rankColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
              ]
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Image.network(
                  rankImgUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shield, size: 80, color: rankColor),
                ),
              ),
              const SizedBox(width: 20),
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
                          color: rankColor,
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
      ],
    );
  }

  // --- Helpers de Estilo (Copiados de tu código) ---
  String _getRankImageUrl(String tier) {
    String t = tier.toLowerCase();
    if (t == 'unranked') return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblems/unranked.png";
    return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblems/emblem-$t.png";
  }

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
      case 'CHALLENGER': return const Color(0xFFF4C874);
      default: return Colors.grey;
    }
  }

  Gradient _getRankGradient(String tier) {
    Color base = _getRankColor(tier);
    return LinearGradient(
      colors: [const Color(0xFF1E2328), base.withOpacity(0.25)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
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