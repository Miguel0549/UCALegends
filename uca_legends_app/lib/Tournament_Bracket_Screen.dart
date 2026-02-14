import 'package:flutter/material.dart';
import 'api_service.dart';

// 1. CAMBIO A STATEFUL WIDGET PARA PODER REFRESCAR LA PANTALLA
class TournamentBracketScreen extends StatefulWidget {
  final int tournamentId;
  final bool isAdmin;
  final String status;

  const TournamentBracketScreen({super.key, required this.tournamentId,this.isAdmin = false, required this.status});

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  late Future<List<dynamic>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _loadMatches(); // Cargamos los datos por primera vez
  }

  // Función maestra para refrescar el bracket
  void _loadMatches() {
    setState(() {
      _matchesFuture = ApiService.getTournamentMatches(widget.tournamentId);
    });
  }

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
      body: Container(
        decoration: const BoxDecoration(
          // ... (tu gradiente actual) ...
        ),
        child: SafeArea(
          child: Column(
            children: [
              // APP BAR ACTUALIZADA
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
                    // BOTÓN DE REFRESCAR (Siempre visible)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                      onPressed: _loadMatches,
                    ),
                    // 2. BOTÓN DE CANCELAR (Solo para ADMIN)
                    if (widget.isAdmin && widget.status != 'CANCELADO' && widget.status != 'FINALIZADO')
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        onPressed: () => _showCancelTournamentDialog(context),
                        tooltip: "Cancelar Torneo",
                      ),
                  ],
                ),
              ),

              // CONTENIDO
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _matchesFuture, // Usamos la variable de estado
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
                          return _buildRoundColumn(roundNum, rounds[roundNum]!);
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

  Widget _buildRoundColumn(int roundNum, List<dynamic> matches) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.15),
              border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "RONDA $roundNum",
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 32),
          ...matches.map((match) => _buildMatchCard(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final teamA = match['teamA'];
    final teamB = match['teamB'];
    final winner = match['winner'];
    final String status = match['status'] ?? 'SCHEDULED';

    String nameA = teamA != null ? teamA['name'] : 'TBD';
    String nameB = teamB != null ? teamB['name'] : 'TBD';

    String tagA = teamA != null ? teamA['tag'] : '?';
    String tagB = teamB != null ? teamB['tag'] : '?';

    int? winnerId = winner != null ? winner['id'] : null;
    int? idA = teamA != null ? teamA['id'] : null;
    int? idB = teamB != null ? teamB['id'] : null;

    bool isFinished = status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2329), Color(0xFF16191D)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinished ? Colors.white12 : const Color(0xFFC9AA71).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!isFinished && teamA != null && teamB != null) {
              _showReportDialog(match['id'], nameA, nameB);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  _buildTeamRow(nameA,tagA, isWinner: winnerId == idA && isFinished, isFinished: isFinished, isTop: true),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  _buildTeamRow(nameB,tagB, isWinner: winnerId == idB && isFinished, isFinished: isFinished, isTop: false),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF090A0C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  isFinished ? "FIN" : "VS",
                  style: TextStyle(color: isFinished ? Colors.grey : const Color(0xFFC9AA71), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(String teamName, String teamTag, {required bool isWinner, required bool isFinished, required bool isTop}) {
    bool isLoser = isFinished && !isWinner;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isWinner ? Colors.white.withOpacity(0.03) : Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(isTop ? 12 : 0), bottom: Radius.circular(!isTop ? 12 : 0)),
      ),
      child: Row(
        children: [
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
                teamName != 'TBD' ? teamTag : '?',
                style: TextStyle(color: isLoser ? Colors.grey[600] : Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
          if (isWinner) const Icon(Icons.emoji_events, color: Color(0xFFC9AA71), size: 18),
        ],
      ),
    );
  }

  void _showReportDialog(int matchId, String teamA, String teamB) {
    final TextEditingController matchIdController = TextEditingController();

    // CAMBIAMOS showDialog POR showModalBottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el panel suba con el teclado
      backgroundColor: Colors.transparent, // Para poder redondear los bordes superiores
      builder: (bottomSheetContext) {
        return Padding(
          // ¡ESTA ES LA MAGIA ABSOLUTA!
          // Le da al panel un margen inferior exactamente igual al alto del teclado
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFFC9AA71), width: 2)), // Un toque dorado eSports
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Solo ocupa el espacio necesario
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TÍTULO ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Reportar Resultado", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- CONTENIDO ---
                  Center(child: Text("$teamA  VS  $teamB", style: const TextStyle(color: Color(0xFFC9AA71), fontWeight: FontWeight.bold, fontSize: 18))),
                  const SizedBox(height: 20),
                  const Text(
                    "Introduce el ID de la partida de Riot Games para verificar el ganador automáticamente.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: matchIdController,
                    style: const TextStyle(color: Colors.white),
                    // Al tocar, el teclado empujará todo el panel hacia arriba
                    decoration: const InputDecoration(
                      hintText: "Ej: EUW1_1234567890",
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC9AA71))),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- BOTÓN PRINCIPAL ---
                  SizedBox(
                    width: double.infinity, // Botón ancho para que sea fácil de pulsar
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        String riotId = matchIdController.text.trim();
                        if (riotId.isEmpty) return;

                        Navigator.pop(bottomSheetContext); // Cerramos el panel inferior

                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Procesando resultado..."))
                        );

                        String? result = await ApiService.reportMatchResult(matchId, riotId);

                        if (!mounted) return;

                        if (result == "success") {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Resultado verificado con éxito", style: TextStyle(color: Colors.green)))
                          );
                          _loadMatches(); // Refrescamos la pantalla
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result ?? "Error al procesar"), backgroundColor: Colors.red)
                          );
                        }
                      },
                      child: const Text("VERIFICAR RESULTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCancelTournamentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("¡Peligro!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "¿Estás seguro de que deseas cancelar este torneo de forma permanente? Esta acción no se puede deshacer.",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("VOLVER", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(dialogContext); // Cerramos el modal

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cancelando torneo..."))
                );

                String? result = await ApiService.cancelTournament(widget.tournamentId);

                if (!mounted) return;

                if (result == "success") {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Torneo cancelado con éxito", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      )
                  );
                  // Te devuelve a la pantalla anterior porque el torneo ya no es jugable
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result ?? "Error al cancelar"), backgroundColor: Colors.red)
                  );
                }
              },
              child: const Text("CANCELAR TORNEO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}