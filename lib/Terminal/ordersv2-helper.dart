import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  WebSocket? _socket;
  final StreamController<String> _streamController = StreamController<String>();

  factory WebSocketManager() {
    return _instance;
  }

  WebSocketManager._internal();

  Future<void> connect(String url) async {
    if (_socket == null) {
      try {
        _socket = await WebSocket.connect(url);
        _socket?.listen(
          (data) => _streamController.add(data),
          onError: (error) => _streamController.addError(error),
          onDone: () => _streamController.close(),
        );
      } catch (e) {
        _streamController.addError(e);
      }
    }
  }

  WebSocket? get socket => _socket;

  void add(String message) {
    _socket?.add(message);
  }

  Stream<String> get stream => _streamController.stream;

  void close() {
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    close();
    _streamController.close();
  }
}
