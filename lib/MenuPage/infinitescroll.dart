import 'package:flutter/material.dart';

class Infinitescroll extends StatefulWidget {
  final int childrenWidth;
  final List<Widget> children; 
  final Duration scrollDuration;

  const Infinitescroll({
    super.key,
    required this.childrenWidth,
    required this.children,
    required this.scrollDuration
  });

  @override
  State<Infinitescroll> createState() => _InfinitescrollState();
}

class _InfinitescrollState extends State<Infinitescroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final Animation<Offset> _animation =
      Tween<Offset>(begin: Offset.zero, end: Offset(-widget.childrenWidth + 10, 0))
          .animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this, 
          duration: widget.scrollDuration
          )
          ..repeat()
          ..addListener(() {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // clipBehavior: Clip.hardEdge,
      // decoration: const BoxDecoration(),
      // width: 500,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent
          ], 
          
          // stops: [
          //   0.1,
          //   0.3,
          //   0.7,
          //   0.9
          // ]
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Transform.translate(
          offset: _animation.value,
          child: Row(
            children: widget.children 
            ),
        ),
      ),
    );
  }
}
