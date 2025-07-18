import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LuxuryCard extends StatelessWidget {
  final int rank;
  final double difference;
  final String rivalName;
  final String cardholderName;

  const LuxuryCard({
    super.key,
    required this.rank,
    required this.difference,
    required this.rivalName,
    required this.cardholderName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final themeData = _getThemeForRank(rank);

    return Center(
      child: Container(
        width: screenWidth * 0.91,
        height: screenHeight * 0.26,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: themeData['gradient'],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [themeData['boxShadow']],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: metal chip and amount ahead
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: screenWidth * 0.115,
                  height: screenHeight * 0.042,
                  decoration: BoxDecoration(
                    gradient: themeData['chipGradient'],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                Text(
                  "\$${(difference + 0.01).toStringAsFixed(2)} ${rank == 1 ? 'ahead' : 'away'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _formatRank(rank),
              style: GoogleFonts.megrim(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${rank == 1 ? 'AHEAD OF' : 'BEHIND'}\n$rivalName",
                  style: TextStyle(
                    color: themeData['subtleTextColor'],
                    fontSize: 12,
                  ),
                ),
                Text(
                  cardholderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRank(int rank) {
    final formatted = NumberFormat.decimalPattern().format(rank);
    if (rank == 1) return 'BLK #$formatted';
    if (rank == 2) return 'GLD #$formatted';
    return 'PLT #$formatted';
  }

  Map<String, dynamic> _getThemeForRank(int rank) {
    if (rank == 1) {
      return {
        'gradient': const LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'chipGradient': LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'boxShadow': const BoxShadow(
          color: Colors.grey,
          blurRadius: 20,
          offset: Offset(0, 3),
        ),
        'subtleTextColor': Colors.grey[400],
      };
    } else if (rank == 2) {
      return {
        'gradient': const LinearGradient(
          colors: [Color(0xFFBFA54B), Color(0xFF8C7B3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'chipGradient': const LinearGradient(
          colors: [Color(0xFFF5DEB3), Color(0xFFEEDC82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'boxShadow': const BoxShadow(
          color: Colors.grey,
          blurRadius: 20,
          offset: Offset(0, 3),
        ),
        'subtleTextColor': Colors.white54,
      };
    } else {
      return {
        'gradient': const LinearGradient(
          colors: [Color(0xFFB0B0B0), Color(0xFF909090), Color(0xFFB0B0B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'chipGradient': LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'boxShadow': const BoxShadow(
          color: Colors.grey,
          blurRadius: 20,
          offset: Offset(0, 3),
        ),
        'subtleTextColor': Colors.white54,
      };
    }
  }
}
