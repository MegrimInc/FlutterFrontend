import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ActionSheet extends StatefulWidget {
  const ActionSheet({super.key});

  @override
  State<ActionSheet> createState() => ActionSheetState();
}

class ActionSheetState extends State<ActionSheet> {
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (BuildContext context, Widget? child) {
            return AnimatedContainer(
              color: Colors.blueGrey,
              duration: const Duration(milliseconds: 400),
              height: scrollController.position.userScrollDirection ==
                      ScrollDirection.reverse
                  ? 0
                  : 80,
              child: child,
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('gey faggot'),
              Icon(Icons.home),
              Icon(Icons.shopping_bag),
              Icon(Icons.favorite),
              Icon(Icons.person),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: AnimatedBuilder(
        animation: scrollController,
        builder: (BuildContext context, Widget? child) {
          return AnimatedContainer(
            color: Colors.blueGrey,
            duration: const Duration(milliseconds: 400),
            height: scrollController.position.userScrollDirection ==
                    ScrollDirection.reverse
                ? 0
                : 80,
            child: child,
          );
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.home),
            Icon(Icons.shopping_bag),
            Icon(Icons.favorite),
            Icon(Icons.person),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff3F3F3F),
              Color(0xff1E1E1E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                "Hide On Scroll",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: 50,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                separatorBuilder: (context, index) => const SizedBox(
                  height: 20,
                ),
                itemBuilder: (context, index) => Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(15)),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}