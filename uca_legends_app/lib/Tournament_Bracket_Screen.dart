import 'package:flutter/material.dart';
import 'api_service.dart';

class TournamentBracketScreen extends StatelessWidget {
  final int tournamentId;

  const TournamentBracketScreen({super.key, required this.tournamentId});

  // Función para agrupar las partidas por su número de ronda
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
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        title: Text("CUADRO - TORNEO #$tournamentId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getTournamentMatches(tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("El cuadro aún no se ha generado.", style: TextStyle(color: Colors.grey)));
          }

          final matches = snapshot.data!;
          final rounds = _groupMatchesByRound(matches);

          // Ordenamos las rondas (1, 2, 3...)
          final roundKeys = rounds.keys.toList()..sort();

          // Scroll Horizontal para navegar entre rondas
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roundKeys.map((roundNum) {
                return _buildRoundColumn(roundNum, rounds[roundNum]!);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS DE LA UI ---

  Widget _buildRoundColumn(int roundNum, List<dynamic> matches) {
    return Container(
      width: 280, // Ancho fijo para cada columna (ronda)
      margin: const EdgeInsets.only(right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la ronda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD32F2F), width: 2)),
            ),
            child: Text(
              "RONDA $roundNum",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Lista de enfrentamientos en esta ronda
          ...matches.map((match) => _buildMatchCard(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    // Extraemos datos manejando posibles nulos si un equipo aún no está asignado
    final teamA = match['teamA'];
    final teamB = match['teamB'];
    final winner = match['winner'];
    final String status = match['status'] ?? 'SCHEDULED';

    String nameA = teamA != null ? teamA['name'] : 'TBD (Por decidir)';
    String nameB = teamB != null ? teamB['name'] : 'TBD (Por decidir)';

    int? winnerId = winner != null ? winner['id'] : null;
    int? idA = teamA != null ? teamA['id'] : null;
    int? idB = teamB != null ? teamB['id'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Equipo A
          _buildTeamRow(nameA, isWinner: winnerId == idA && winnerId != null),

          // Divisor central (VS)
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
            child: Center(
              child: Container(
                color: const Color(0xFF090A0C),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  status == 'FINISHED' ? 'FINALIZADO' : 'VS',
                  style: TextStyle(color: status == 'FINISHED' ? Colors.grey : const Color(0xFFC9AA71), fontSize: 10),
                ),
              ),
            ),
          ),

          // Equipo B
          _buildTeamRow(nameB, isWinner: winnerId == idB && winnerId != null),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String teamName, {required bool isWinner}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              teamName,
              style: TextStyle(
                color: isWinner ? Colors.white : Colors.grey[400],
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isWinner)
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}