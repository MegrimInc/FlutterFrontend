import 'dart:math';

class Categories {
  final int barId;
  final List<int> tag172;
  final List<int> tag173;
  final List<int> tag174;
  final List<int> tag175;
  final List<int> tag176;
  final List<int> tag177;
  final List<int> tag178;
  final List<int> tag179;
  final List<int> tag181;
  final List<int> tag182;
  final List<int> tag183;
  final List<int> tag184;
  final List<int> tag186;

  Categories({
    required this.barId,
    required this.tag172,
    required this.tag173,
    required this.tag174,
    required this.tag175,
    required this.tag176,
    required this.tag177,
    required this.tag178,
    required this.tag179,
    required this.tag181,
    required this.tag182,
    required this.tag183,
    required this.tag184,
    required this.tag186,
  });


  // Method to get 6 random drink IDs from each category list
  Map<String, List<int>> getRandomDrinkIds() {
    final random = Random();
    return {
      'tag172': _getRandomSubset(tag172, random),
      'tag173': _getRandomSubset(tag173, random),
      'tag174': _getRandomSubset(tag174, random),
      'tag175': _getRandomSubset(tag175, random),
      'tag176': _getRandomSubset(tag176, random),
      'tag177': _getRandomSubset(tag177, random),
      'tag178': _getRandomSubset(tag178, random),
      'tag179': _getRandomSubset(tag179, random),
      'tag181': _getRandomSubset(tag181, random),
      'tag182': _getRandomSubset(tag182, random),
      'tag183': _getRandomSubset(tag183, random),
      'tag184': _getRandomSubset(tag184, random),
      'tag186': _getRandomSubset(tag186, random),
    };
  }

  // Helper method to return a random subset of 6 or fewer elements
  List<int> _getRandomSubset(List<int> list, Random random) {
    if (list.isEmpty) return [];
    return (list..shuffle(random)).take(6).toList();
  }
}