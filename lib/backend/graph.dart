import 'dart:collection';

class Graph {
  // Map to store the adjacency list
  Map<String, List<String>> adjList = {};

  // Function to add a node
  void addNode(String node) {
    if (!adjList.containsKey(node)) {
      adjList[node] = [];
    }
  }

  // Function to add an edge from a user to a bar
  void addEdge(String user, String bar) {
    // Ensure both the user and bar nodes exist
    addNode(user);
    addNode(bar);

    // Add the bar to the user's list of bars
    adjList[user]!.add(bar);
  }

  // Function to display the graph
  void displayGraph() {
    adjList.forEach((node, edges) {
      print('$node: ${edges.join(', ')}');
    });
  }
}

