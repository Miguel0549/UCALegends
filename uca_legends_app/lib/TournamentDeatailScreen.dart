import 'package:flutter/material.dart';
import 'api_service.dart'; // Asegúrate de que la ruta coincida con tu proyecto

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  // Usamos un Future que podremos recargar cuando sea necesario
  late Future<List<dynamic>> _tournamentFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Método para cargar/recargar los datos
  void _refreshData() {
    setState(() {
      _tournamentFuture = Future.wait([
        ApiService.getTournamentById(widget.tournamentId),
        ApiService.getInscribedCount(widget.tournamentId),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C), // Fondo oscuro Legends
      appBar: AppBar(
        title: const Text("DETALLES DEL TORNEO",
            style: TextStyle(letterSpacing: 1.5, fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tournamentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
          }
          if (!snapshot.hasData || snapshot.data![0] == null) {
            return const Center(child: Text("Error al cargar los datos", style: TextStyle(color: Colors.white)));
          }

          // Parseamos los datos devueltos por el Future.wait
          final torneo = snapshot.data![0] as Map<String, dynamic>;
          final int nInscritos = snapshot.data![1] as int;

          final int maxTeams = torneo['maxTeams'] ?? 0;
          final String status = torneo['status'] ?? 'CERRADO';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: Nombre y Región
                _buildHeader(torneo['name'] ?? 'Torneo', torneo['region'] ?? 'EUW'),
                const SizedBox(height: 24),

                // Barra de progreso de inscripciones
                _buildInscribedCounter(nInscritos, maxTeams),
                const SizedBox(height: 24),

                // Card de Estadísticas
                _buildStatsCard(torneo['gameMode'], status),
                const SizedBox(height: 24),

                // Información Detallada
                _buildInfoSection("FECHA DE INICIO", torneo['fechaInicio']?.toString().replaceAll('T', ' ').substring(0,16) ?? 'Por determinar'),
                _buildInfoSection("MODO DE JUEGO", torneo['gameMode'] ?? "5v5"),

                const SizedBox(height: 40),

                // Botón de Acción
                _buildJoinButton(context, status, nInscritos, maxTeams),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // --- WIDGETS DE APOYO (UI) ---
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String name, String region) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD32F2F)),
          ),
          child: Text(region, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInscribedCounter(int actual, int max) {
    double porcentaje = max > 0 ? actual / max : 0;
    // Evitamos que la barra visualmente pase del 100% por algún error
    if (porcentaje > 1.0) porcentaje = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EQUIPOS INSCRITOS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$actual / $max", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              backgroundColor: Colors.white10,
              color: const Color(0xFFD32F2F),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String? mode, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("MODO", mode ?? "5V5"),
          _statItem("ESTADO", status, color: status == 'ABIERTO' ? Colors.green : Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Divider(color: Colors.white10, height: 24),
        ],
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context, String status, int inscritos, int max) {
    bool isOpen = status == 'ABIERTO';
    bool isFull = inscritos >= max;
    bool canJoin = isOpen && !isFull;

    // Texto dinámico para el botón
    String buttonText = "INSCRIBIR EQUIPO";
    if (!isOpen) {
      buttonText = "INSCRIPCIONES CERRADAS";
    } else if (isFull) {
      buttonText = "TORNEO LLENO";
    }

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canJoin ? const Color(0xFFD32F2F) : Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: canJoin ? () => _handleJoin(context) : null,
        child: Text(
          buttonText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // --- LÓGICA DE INSCRIPCIÓN ---
  // ---------------------------------------------------------------------------

  void _handleJoin(BuildContext context) async {
    // 1. Mostrar un pequeño diálogo de carga para que la app no parezca "congelada"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
    );

    // 2. Hacer la llamada al backend usando el ApiService
    String? result = await ApiService.joinTournament(widget.tournamentId);

    // 3. Quitar el diálogo de carga
    if (mounted) Navigator.pop(context);

    // 4. Analizar el resultado
    if (result == "success") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Inscripción realizada con éxito!"), backgroundColor: Colors.green),
        );
      }
      // 5. ¡LA MAGIA!: Volvemos a pedir los datos a la BD y actualizamos la UI
      _refreshData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $result"), backgroundColor: Colors.red),
        );
      }
    }
  }
}