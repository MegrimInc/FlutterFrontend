import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSStyleKeypad extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final VoidCallback? onResend;
  final VoidCallback? onCancel;

  const IOSStyleKeypad({
    super.key,
    required this.controller,
    this.onCompleted,
    this.onResend,
    this.onCancel,
  });

  @override
  IOSStyleKeypadState createState() => IOSStyleKeypadState();
}

class IOSStyleKeypadState extends State<IOSStyleKeypad> {
  void _handleCompletion(String code) {
    if (widget.onCompleted != null) {
      widget.onCompleted!(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Text(
              widget.controller
                  .text, // This line now shows the actual digits entered by the user.
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          _buildKeypad(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('0'),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // RESEND
            GestureDetector(
              onTap: () {
                if (widget.onResend != null) {
                  widget.onResend!(); // Trigger the resend function
                  HapticFeedback.heavyImpact();
                  HapticFeedback.vibrate(); 
                   
                 
                }
              },
              child: Container(
                width: 120,
                height: 60,
                color: Colors.transparent,
                child: const Center(
                  child: Text(
                    'resend',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
            // BACKSPACE
            _buildBackspaceKey()
          ],
        )
      ],
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () {
        debugPrint('Key pressed: $value');
        if (widget.controller.text.length < 6) {
          setState(() {
            widget.controller.text += value;
          });
          debugPrint('Current input: ${widget.controller.text}');
          if (widget.controller.text.length == 6) {
            debugPrint('Input complete: ${widget.controller.text}');
            _handleCompletion(widget.controller.text);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 75,
        height: 75,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(54, 188, 188, 188),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return GestureDetector(
      onTap: () {
        if (widget.controller.text.isNotEmpty) {
          // Handle deletion
          setState(() {
            widget.controller.text = widget.controller.text
                .substring(0, widget.controller.text.length - 1);
            debugPrint(
                'Current input after backspace: ${widget.controller.text}');
          });
        } else {
          // Handle cancel
          if (widget.onCancel != null) {
            widget.onCancel!(); // Hide the overlay if cancel is tapped
          }
        }
      },
      child: Container(
        width: 120,
        height: 60,
        color: Colors.transparent,
        child: Center(
          child: Text(
            widget.controller.text.isNotEmpty ? 'delete' : 'cancel',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}