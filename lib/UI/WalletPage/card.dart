import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryCard extends StatelessWidget {
  final String rank;
  final String validThru;
  final String cardholderName;
  final String brand;
  final bool isBlack; // New flag to switch themes

  const LuxuryCard({
    super.key,
    required this.rank,
    required this.validThru,
    required this.cardholderName,
    required this.brand,
    required this.isBlack,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isBlack
        ? const LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFB0B0B0),
              Color(0xFF909090),
              Color(0xFFB0B0B0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final boxShadow = isBlack
        ? const BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        : const BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          );

    return Center(
      child: Container(
        width: 340,
        height: 210,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [boxShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: logo and tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "M",
                  style: GoogleFonts.megrim(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                 brand.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "VALID THRU\n$validThru",
                  style: TextStyle(
                    color: isBlack ? Colors.grey[400] : Colors.white70,
                    fontSize: 10,
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
}
