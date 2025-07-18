import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/UI/LeaderboardPage/card.dart';
import 'package:megrim/config.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class LeaderboardPage extends StatefulWidget {
  final VoidCallback onClose;
  final int merchantId;
  final int customerId;

  const LeaderboardPage({
    super.key,
    required this.onClose,
    required this.merchantId,
    required this.customerId,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  String customerFullName = '';
  String rivalFullName = '';
  Offset? _startPosition;
  double? difference;
  int? rank;
  bool isLoadingRank = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );
    _blurAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchRank();
  }

  Future<void> _fetchRank() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.postgresHttpBaseUrl}/customer/getRank?merchantId=${widget.merchantId}&customerId=${widget.customerId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          rank = data['rank'];
          difference = (data['difference'] as num?)?.toDouble();
          rivalFullName = data['rivalFullName'] ?? '';
          customerFullName = data['customerFullName'] ?? '';
          isLoadingRank = false;
        });
      } else {
        setState(() => isLoadingRank = false);
        debugPrint('Rank fetch failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoadingRank = false);
      debugPrint('Rank fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: (details) {
          _startPosition = details.globalPosition;
        },
        onPanUpdate: (details) {
          if (_startPosition != null) {
            final dy = details.globalPosition.dy - _startPosition!.dy;
            final dx = details.globalPosition.dx - _startPosition!.dx;
            if (dy > 50 && dy.abs() > dx.abs()) {
              _controller.reverse().then((_) => widget.onClose());
              _startPosition = null;
            }
          }
        },
        onPanEnd: (_) {
          _startPosition = null;
        },
        child: AnimatedBuilder(
          animation: _blurAnimation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value,
                    ),
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                  FadeTransition(
                    opacity: _controller,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.11),
                        Text(
                          (LocalDatabase.getMerchantById(widget.merchantId)
                                      ?.nickname ??
                                  'MERCHANT')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Text(
                                "This card shows your current rank at ${LocalDatabase.getMerchantById(widget.merchantId)?.name ?? 'this store'}, based on how much you've spent compared to other customers. Higher ranks can mean special recognition and perks.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  //fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                                
                              ),
                              SizedBox(height: 10),
                              Text(
                                "For more information about the benefits available for each rank, please contact the location near you.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        isLoadingRank
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : LuxuryCard(
                                rank: rank ?? 0,
                                //rank: 2,
                                difference: difference ?? 0.0,
                                rivalName: rivalFullName,
                                cardholderName: customerFullName,
                              ),
                        const Spacer(flex: 4),
                        Center(
                          child: Shimmer.fromColors(
                            baseColor: Colors.white54,
                            highlightColor: Colors.white,
                            period: const Duration(milliseconds: 1500),
                            child: Text(
                              'Swipe Down to Go Back',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.11),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
