import 'package:mobile_scanner/mobile_scanner.dart';

class CameraControllerSingleton {
  MobileScannerController? _controller;

  MobileScannerController get controller {
    _controller ??= MobileScannerController();
    return _controller!;
  }

  Future<void> initialize() async {
    _controller ??= MobileScannerController();
    await _controller!.start();
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

final CameraControllerSingleton cameraControllerSingleton = CameraControllerSingleton();
