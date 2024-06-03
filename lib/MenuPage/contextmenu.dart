import 'package:flutter/cupertino.dart';

class ContextMenu extends StatelessWidget {
  final String category;

  const ContextMenu({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text('Options for $category'),
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () {
            // Handle action 1
            Navigator.pop(context);
          },
          child: const Text('Action 1'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            // Handle action 2
            Navigator.pop(context);
          },
          child: const Text('Action 2'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('Cancel'),
      ),
    );
  }
}
