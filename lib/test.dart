import 'package:barzzy_app1/Backend/graph.dart';
import 'package:flutter/material.dart';

class Testing extends StatelessWidget {
   Testing({super.key});

  // Initialize your graph and add some edges for testing
  final Graph graph = Graph();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Add some users and bars
            graph.addEdge('user1', 'bar1');
            graph.addEdge('user1', 'bar2');
            graph.addEdge('user2', 'bar1');
            graph.addEdge('user2', 'bar3');
            graph.addEdge('user3', 'bar2');

            // Display the graph (for testing, prints to console)
            graph.displayGraph();
          },
          child: const Text('Display Graph'),
        ),
      ),
    );
  }
}