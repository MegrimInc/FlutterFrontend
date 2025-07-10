import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/UI/WalletPage/card.dart';
import 'package:megrim/config.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class WalletPage extends StatefulWidget {
  final VoidCallback onClose;
  final int merchantId;
  final int customerId;
  final bool isBlack;

  const WalletPage({
    super.key,
    required this.onClose,
    required this.merchantId,
    required this.customerId,
    required this.isBlack,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  String firstName = '';
  String lastName = '';
  Offset? _startPosition;

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
    _fetchCustomerName(widget.customerId);
  }

  Future<void> _fetchCustomerName(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.postgresHttpBaseUrl}/customer/getNames/$customerId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          firstName = data['firstName'] ?? '';
          lastName = data['lastName'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Name fetch error: $e');
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
                    child: Container(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                  FadeTransition(
                    opacity: _controller,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                         const Spacer(flex: 2),
                        const Text(
                          '\$12.99 / month',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "Unlock exclusive benefits designed for our most loyal members. As a Platinum tier subscriber, you'll receive early access to new product drops, personalized offers tailored to your preferences, and complimentary upgrades when available.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 25),
                        LuxuryCard(
                          rank: '1st',
                          validThru: '12/28/25',
                          cardholderName:
                              '${firstName.isNotEmpty ? firstName[0].toUpperCase() + firstName.substring(1) : ''} '
                              '${lastName.isNotEmpty ? '${lastName[0].toUpperCase()}.' : ''}',
                          brand:
                              (LocalDatabase.getMerchantById(widget.merchantId)
                                          ?.nickname ??
                                      'CARD')
                                  .toUpperCase(),
                          isBlack: widget.isBlack,
                        ),
                        const Spacer(flex: 2),
                       
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
        const Spacer(flex: 2),
                        buildPurchaseButton(() {
                          HapticFeedback.heavyImpact();
                          // purchase logic
                        }),
                        const Spacer(flex: 2),
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

  Widget buildPurchaseButton(VoidCallback onPressed) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 300,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Purchase',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
