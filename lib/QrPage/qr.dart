import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrPage extends StatefulWidget {
  final MobileScannerController cameraController;

  const QrPage({required this.cameraController, super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  void _startCamera() {
    try {
      widget.cameraController.start(); // Attempt to start the camera
      debugPrint('Camera started successfully.');
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MobileScanner(
        controller: widget.cameraController, // Use the passed controller
        fit: BoxFit.cover,
        onDetect: (BarcodeCapture barcode) {
          final String? code = barcode.barcodes.first.rawValue;
          if (code != null) {
            _handleQRCode(context, code);
          }
        },
      ),
    );
  }

  void _handleQRCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scanned QR Code'),
        content: Text(code),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.cameraController.dispose();
    super.dispose();
  }
}
