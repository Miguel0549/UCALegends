import 'package:flutter/material.dart';
import 'api_service.dart';

class TournamentBracketScreen extends StatelessWidget {
  final int tournamentId;

  const TournamentBracketScreen({super.key, required this.tournamentId});

  Map<int, List<dynamic>> _groupMatchesByRound(List<dynamic> matches) {
    Map<int, List<dynamic>> grouped = {};
    for (var match in matches) {
      int round = match['round'] ?? 1;
      if (!grouped.containsKey(round)) {
        grouped[round] = [];
      }
      grouped[round]!.add(match);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. FONDO CON GRADIENTE GAMING
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF13151A), // Azul muy oscuro
              Color(0xFF090A0C), // Casi negro
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // APP BAR CUSTOM
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "CUADRO DEL TORNEO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance para centrar el título
                  ],
                ),
              ),

              // CONTENIDO DEL BRACKET
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.getTournamentMatches(tournamentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFC9AA71)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("El cuadro aún no se ha generado.", style: TextStyle(color: Colors.grey)));
                    }

                    final matches = snapshot.data!;
                    final rounds = _groupMatchesByRound(matches);
                    final roundKeys = rounds.keys.toList()..sort();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: roundKeys.map((roundNum) {
                          return _buildRoundColumn(roundNum, rounds[roundNum]!, context);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE LA UI RE-DISEÑADOS ---

  Widget _buildRoundColumn(int roundNum, List<dynamic> matches, BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 48), // Más espacio entre rondas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // CABECERA DE RONDA ESTILO "BADGE"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.15),
              border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "RONDA $roundNum",
              style: const TextStyle(
                color: Color(0xFFFF5252),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // LISTA DE PARTIDOS
          ...matches.map((match) => _buildMatchCard(match, context)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, BuildContext context) {
    final teamA = match['teamA'];
    final teamB = match['teamB'];
    final winner = match['winner'];
    final String status = match['status'] ?? 'SCHEDULED';

    String nameA = teamA != null ? teamA['name'] : 'TBD';
    String nameB = teamB != null ? teamB['name'] : 'TBD';

    int? winnerId = winner != null ? winner['id'] : null;
    int? idA = teamA != null ? teamA['id'] : null;
    int? idB = teamB != null ? teamB['id'] : null;

    bool isFinished = status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        // Fondo de la tarjeta con ligero gradiente
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E2329),
            const Color(0xFF16191D),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        // Borde dorado sutil si está pendiente, gris si terminó
        border: Border.all(
          color: isFinished ? Colors.white12 : const Color(0xFFC9AA71).withOpacity(0.5),
          width: 1.5,
        ),
        // Sombra suave para dar relieve
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!isFinished && teamA != null && teamB != null) {
              _showReportDialog(context, match['id'], nameA, nameB);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  // EQUIPO A
                  _buildTeamRow(nameA, isWinner: winnerId == idA && isFinished, isFinished: isFinished, isTop: true),
                  // LINEA DIVISORIA
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  // EQUIPO B
                  _buildTeamRow(nameB, isWinner: winnerId == idB && isFinished, isFinished: isFinished, isTop: false),
                ],
              ),
              // INSIGNIA CENTRAL "VS"
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF090A0C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  isFinished ? "FIN" : "VS",
                  style: TextStyle(
                    color: isFinished ? Colors.grey : const Color(0xFFC9AA71),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(String teamName, {required bool isWinner, required bool isFinished, required bool isTop}) {
    // Si el partido terminó y NO es el ganador, lo atenuamos mucho.
    bool isLoser = isFinished && !isWinner;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isWinner ? Colors.white.withOpacity(0.03) : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTop ? 12 : 0),
          bottom: Radius.circular(!isTop ? 12 : 0),
        ),
      ),
      child: Row(
        children: [
          // AVATAR DEL EQUIPO (Círculo con la inicial)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isLoser ? Colors.grey[800] : const Color(0xFF2A2E33),
              shape: BoxShape.circle,
              border: Border.all(color: isWinner ? const Color(0xFFC9AA71) : Colors.transparent),
            ),
            child: Center(
              child: Text(
                teamName != 'TBD' ? teamName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isLoser ? Colors.grey[600] : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // NOMBRE DEL EQUIPO
          Expanded(
            child: Text(
              teamName,
              style: TextStyle(
                color: isLoser ? Colors.grey[600] : (isWinner ? Colors.white : Colors.grey[300]),
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ICONO DE VICTORIA (Trofecito o check)
          if (isWinner)
            const Icon(Icons.emoji_events, color: Color(0xFFC9AA71), size: 18),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, int matchId, String teamA, String teamB) {
    final TextEditingController matchIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Reportar Resultado", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$teamA  VS  $teamB", style: const TextStyle(color: Color(0xFFC9AA71), fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Introduce el ID de la partida de Riot Games para verificar el ganador automáticamente.",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: matchIdController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ej: EUW1_1234567890",
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC9AA71))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              onPressed: () async {
                String riotId = matchIdController.text.trim();
                if (riotId.isEmpty) return;

                Navigator.pop(context); // Cerramos el diálogo primero

                // Mostramos un loading de mentira (opcional)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Procesando resultado...")));

                // Llamamos al backend
                String? result = await ApiService.reportMatchResult(matchId, riotId);

                if (result == "success") {
                  // TODO: Aquí deberías recargar la pantalla para ver el ganador y la nueva ronda si se generó
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resultado verificado con éxito", style: TextStyle(color: Colors.green))));
                } else {
                  // El backend nos dirá si no somos el líder
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "Error"), backgroundColor: Colors.red));
                }
              },
              child: const Text("VERIFICAR GANADOR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}