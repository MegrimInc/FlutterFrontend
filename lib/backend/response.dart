import 'dart:math';

import 'package:barzzy_app1/Backend/user.dart';

final _random = Random();

class Response {
  static List<String> negativeResponses = [
    "Sorry, I'm not sure we have that. Can I get you something else?",
    "Whoops, looks like we're fresh out of that. What else can I get you?",
    "Zoinks Scoob! Looks like we have a mystery on our hands. I couldn't find your drink.",
    "ZooooWeeeeMAMA! I couldn't find your drink! If we don't get you one soon I might just have to call the fun police. Let's find you another ASAP."
  ];

  static List<String> positiveResponses = [
    "Heres your drink kind sir",
    "Here you are sir",
    "I found you these, anything else I can get you",
  ];

  static String getRandomNegativeResponse() {
    final randomIndex = _random.nextInt(negativeResponses.length);
    return negativeResponses[randomIndex];
  }

  void addNegativeResponse(User user, String barId) {
    String response = getRandomNegativeResponse();
    user.addResponseToHistory(barId, response);
  }

  static String getRandomPositiveResponse() {
    final randomIndex = _random.nextInt(positiveResponses.length);
    return positiveResponses[randomIndex];
  }

  void addPositiveResponse(User user, String barId) {
    String response = getRandomPositiveResponse();
    user.addResponseToHistory(barId, response);
  }
}
