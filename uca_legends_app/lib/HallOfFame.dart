import 'package:flutter/material.dart';

class HallOfFameCard extends StatelessWidget {
  final Map<String, dynamic> tournament;

  const HallOfFameCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    // Extraemos datos. Usamos ?? por seguridad si algún campo viene null del backend
    String winnerName = tournament['winnerName'] ?? "Sin Ganador";
    String tournamentName = tournament['tournamentName'] ?? "Torneo";
    String dateRaw = tournament['fechaInicio'] ?? "";

    // Formatear fecha simple (cortar la hora si viene en formato ISO)
    String date = dateRaw.length > 10 ? dateRaw.substring(0, 10) : dateRaw;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Degradado oscuro metálico
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2328), Color(0xFF090A0C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Borde dorado fino
        border: Border.all(color: const Color(0xFFC9AA71).withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // Fondo decorativo (Copa gigante transparente)
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(Icons.emoji_events, size: 90, color: Colors.white.withOpacity(0.03)),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // --- ICONO COPA ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9AA71).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC9AA71), width: 1),
                  ),
                  child: const Icon(Icons.emoji_events, color: Color(0xFFC9AA71), size: 28),
                ),

                const SizedBox(width: 16),

                // --- TEXTOS ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etiqueta "CAMPEÓN"
                      Text(
                        "CAMPEÓN",
                        style: TextStyle(
                          color: const Color(0xFFC9AA71).withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Nombre del Ganador (Grande)
                      Text(
                        winnerName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Beaufort', // O la fuente por defecto
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Detalles del torneo
                      Text(
                        "$tournamentName  •  $date",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- REGIÓN ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tournament['region'] ?? "EUW",
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}