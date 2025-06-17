import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DMPage extends StatefulWidget {
  final String? contactName;

  const DMPage({super.key, this.contactName});

  @override
  State<DMPage> createState() => _DMPageState();
}

class _DMPageState extends State<DMPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: '');
  final List<Map<String, dynamic>> _messages = [];
  String? _finalizedName;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'text': text, 'isMe': true});
      });
      _controller.clear();
    }
  }

  void _finalizeName(String value) {
    final trimmed = value;
    if (trimmed.isEmpty) return;
    setState(() {
      _finalizedName = '@$trimmed';
    });
  }

  @override
  void initState() {
    super.initState();
    _finalizedName = widget.contactName;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: _nameController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNameSet = _finalizedName != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.black,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: isNameSet
            ? Text(
                _finalizedName!,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  const Text(
                    '@',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _finalizeName,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            RegExp(r'\s')), // blocks all whitespace
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toLowerCase(),
                            selection: newValue.selection,
                          ),
                        ),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Spacer()
                ],
              ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.menu, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                return Align(
                  alignment: msg['isMe']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg['isMe'] ? Colors.white : Colors.white60,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: msg['isMe'] ? Colors.black : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isNameSet)
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 50,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}
