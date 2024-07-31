import 'dart:math';

import 'package:barzzy_app1/Backend/user.dart';

final _random = Random();

class Response {
   static List<String> genericNegativeResponses = [
    "Hmmm, I couldn't find any drinks for *\$query. Anything else you'd like?",
    "No drinks matching *\$query. Want to try something else?",
    "Sorry, nothing came up for *\$query. How about another choice?",
    "No luck finding drinks for *\$query. Can I get you something else?",
    "Couldn't find any drinks for *\$query. What else can I get for you?",
    "No results for *\$query. Maybe another drink?",
    "I didn't find any drinks for *\$query. How about another option?",
    "Looks like we don't have anything for *\$query. Anything else you want?",
    "No matches for *\$query. Let's find something else!",
    "Sorry, no drinks for *\$query. Want to try a different drink?",
    "Couldn't locate any drinks for *\$query. Let's try a new search!",
    "We have no drinks for *\$query. How about another option?",
    "Nothing matching *\$query. How about something else?",
    "I couldn't find drinks for *\$query. How about another choice?",
    "No drinks available for *\$query. Maybe another idea?",
    "Sorry, no luck with *\$query. Can I suggest something else?",
    "No matches found for *\$query. Want to try something else?",
    "No results for *\$query. Anything else you'd like to try?",
    "No drinks matching *\$query. Let's try another search!",
    "Couldn't find any drinks for *\$query. Want to search again?",
    "Nothing came up for *\$query. How about another drink?",
    "No drinks found for *\$query. Can I offer another suggestion?",
    "Sorry, we couldn't find drinks for *\$query. Try something else?",
    "No drinks for *\$query. Let's see what else we have!",
    "No matches for *\$query. Maybe a different drink?",
    "Looks like we don't have anything for *\$query. Try another search?",
    "Couldn't find drinks for *\$query. How about another choice?",
    "No drinks matching *\$query. Let's try another option.",
    "Nothing found for *\$query. How about something else?",
    "No drinks available for *\$query. Want to try a new search?",
    "Couldn't find any matches for *\$query. How about another drink?",
    "No results for *\$query. Maybe another choice?",
    "Sorry, no matches for *\$query. How about another option?",
    "We couldn't find drinks for *\$query. Can I suggest something else?",
    "Nothing matching *\$query. Want to try another search?",
    "Sorry, we have no drinks for *\$query. Let's find something else!",
    "Couldn't locate drinks for *\$query. How about a different drink?",
    "No matches for *\$query. Want to try something different?",
    "Nothing found for *\$query. Let's explore other options.",
    "We couldn't find any drinks for *\$query. How about something else?",
    "No luck with *\$query. Want to search for another drink?",
    "Couldn't find anything for *\$query. Let's try another option!",
    "No drinks matching *\$query. Can I get you something else?",
    "Nothing came up for *\$query. How about another choice?",
    "We have no drinks for *\$query. Maybe a different search?",
    "No matches found for *\$query. Want to search again?",
    "Sorry, nothing for *\$query. Can I offer another drink?",
    "Couldn't find drinks for *\$query. Let's try something else.",
    "No results for *\$query. How about a different drink?"
  "I couldn't find any drinks for *\$query. Want to try something different?",
  "No luck with *\$query. How about another option?",
  "Seems like we don't have drinks for *\$query. Can I get you something else?",
  "Couldn't spot any drinks for *\$query. Maybe another choice?",
  "No matches for *\$query. Perhaps a different drink?",
  "Looks like we're out of drinks for *\$query. Anything else on your mind?",
  "Couldn't find *\$query drinks. Let's try another search!",
  "Nothing available for *\$query. How about another type?",
  "No drinks found for *\$query. Let's explore other options.",
  "Sorry, no results for *\$query. How about another suggestion?",
  "No drinks here for *\$query. Let's find something else!",
  "We couldn't locate drinks for *\$query. Want to search again?",
  "No luck with drinks for *\$query. Anything else you're in the mood for?",
  "Nothing for *\$query right now. How about another search?",
  "Didn't find any *\$query drinks. Let's try something else!",
  "No drinks matching *\$query. How about a different idea?",
  "Couldn't find anything for *\$query. Another round?",
  "Sorry, no drinks for *\$query. How about a different selection?",
  "No matches for *\$query drinks. Let's see what else we have!",
  "Nothing for *\$query at the moment. Can I suggest something else?",
  "No drinks available for *\$query. What else can I get you?",
  "Couldn't find any drinks for *\$query. Maybe another choice?",
  "No drinks for *\$query. Let's find another option.",
  "No options for *\$query. How about trying something else?",
  "Couldn't find drinks for *\$query. How about another type?",
  "Nothing matching *\$query. Let's explore different choices!",
  "No drinks here for *\$query. Let's look at other options.",
  "No luck with *\$query drinks. Anything else you're interested in?",
  "No matches found for *\$query. Can I get you something else?",
  "Couldn't locate any *\$query drinks. Let's search again!",
  "Nothing available for *\$query. How about a new search?",
  "No drinks for *\$query. Shall we try something different?",
  "Couldn't find anything for *\$query. What else can I get for you?",
  "No matches for *\$query. Let's find another choice.",
  "No drinks for *\$query. Perhaps another option?",
  "Nothing came up for *\$query. Let's explore other ideas.",
  "Couldn't find drinks for *\$query. Maybe another choice?",
  "No results for *\$query. Shall we try a different drink?",
  "No drinks found for *\$query. Want to look at something else?",
  "Couldn't spot any *\$query drinks. Let's see what else we have!",
  "No luck with drinks for *\$query. How about a new choice?",
  "Sorry, nothing for *\$query. Can I suggest another drink?",
  "No drinks matching *\$query. Shall we look for something else?",
  "Couldn't find *\$query drinks. Let's try a different option!",
  "No matches for *\$query. How about another idea?",
  "No drinks here for *\$query. Let's try searching again.",
  "No results for *\$query. Want to try another option?",
  "Nothing for *\$query right now. How about a different search?",
  "Couldn't locate drinks for *\$query. What else would you like?",
  "No matches for *\$query. Can I offer another drink?"
];
  


  static List<String> genericPositiveResponses = [
    "I found \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
    "Great choice! There are \$numberOfDrinks \$drinkWord for *\$query. Let's check them out!",
    "Here are \$numberOfDrinks \$drinkWord that match *\$query. Let's get you started!",
    "Good news! I found \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "We've got \$numberOfDrinks \$drinkWord for *\$query. Enjoy your selection!",
    "There are \$numberOfDrinks \$drinkWord for *\$query. Let me know what you think!",
    "Found \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
    "Looks like we've got \$numberOfDrinks \$drinkWord for *\$query. Bottoms up!",
    "Perfect! Found \$numberOfDrinks \$drinkWord for *\$query. Let's see what you'd like!",
    "Here's what I found: \$numberOfDrinks \$drinkWord for *\$query. Enjoy your drinks!",
    "You've got \$numberOfDrinks \$drinkWord to choose from for *\$query. Let's dive in!",
    "We have \$numberOfDrinks \$drinkWord for *\$query. Take your pick!",
    "I've found \$numberOfDrinks \$drinkWord for *\$query. Enjoy your drinks!",
    "Cheers! There are \$numberOfDrinks \$drinkWord for *\$query. Let's explore them!",
    "Here are \$numberOfDrinks \$drinkWord for *\$query. What can I get you?",
    "I've got \$numberOfDrinks \$drinkWord for *\$query. Let me know what you'd like!",
    "You've got \$numberOfDrinks \$drinkWord to choose from for *\$query. Let's check them out!",
    "There are \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
    "I found \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Great news! There are \$numberOfDrinks \$drinkWord for *\$query. Let's check them out!",
    "Perfect! We've got \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
    "Looks like there are \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Here's what we have: \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
    "We've got \$numberOfDrinks \$drinkWord for *\$query. Let me know what you think!",
    "Good choice! There are \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Found \$numberOfDrinks \$drinkWord for *\$query. What can I get you?",
    "I've got \$numberOfDrinks \$drinkWord for *\$query. Let me know what you'd like!",
    "You've got \$numberOfDrinks \$drinkWord to choose from for *\$query. Let's see what you'd like!",
    "There are \$numberOfDrinks \$drinkWord for *\$query. Let me know what you think!",
    "I found \$numberOfDrinks \$drinkWord for *\$query. Enjoy your drinks!",
    "Great news! We've got \$numberOfDrinks \$drinkWord for *\$query. Let's dive in!",
    "Perfect! There are \$numberOfDrinks \$drinkWord for *\$query. Enjoy your selection!",
    "Here's what we have: \$numberOfDrinks \$drinkWord for *\$query. Enjoy your drinks!",
    "I've found \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Cheers! There are \$numberOfDrinks \$drinkWord for *\$query. Let's see what you'd like!",
    "Here are \$numberOfDrinks \$drinkWord for *\$query. What can I get you?",
    "I've got \$numberOfDrinks \$drinkWord for *\$query. Let me know what you'd like!",
    "You've got \$numberOfDrinks \$drinkWord to choose from for *\$query. Let's explore them!",
    "We have \$numberOfDrinks \$drinkWord for *\$query. Take your pick!",
    "I found \$numberOfDrinks \$drinkWord for *\$query. Enjoy your drinks!",
    "Good news! There are \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Perfect! We've got \$numberOfDrinks \$drinkWord for *\$query. Let's see what you'd like!",
    "Looks like there are \$numberOfDrinks \$drinkWord for *\$query. Cheers!",
    "Here's what we have: \$numberOfDrinks \$drinkWord for *\$query. Let me know what you think!",
    "We've got \$numberOfDrinks \$drinkWord for *\$query. What can I get you?",
    "Found \$numberOfDrinks \$drinkWord for *\$query. Let's dive in!",
    "I've got \$numberOfDrinks \$drinkWord for *\$query. Let me know what you'd like!",
    "You've got \$numberOfDrinks \$drinkWord to choose from for *\$query. Enjoy your selection!",
    "There are \$numberOfDrinks \$drinkWord for *\$query. Let me know what you think!",
    "I found \$numberOfDrinks \$drinkWord for *\$query. Cheers!"
    "We've got \$numberOfDrinks \$drinkWord for *\$query. Let's take a look!",
  "Found \$numberOfDrinks \$drinkWord for *\$query. What'll it be?",
  "Check these out: \$numberOfDrinks \$drinkWord for *\$query. Your call!",
  "Here's a great selection: \$numberOfDrinks \$drinkWord for *\$query.",
  "Good news! We have \$numberOfDrinks \$drinkWord for *\$query.",
  "You're in luck! \$numberOfDrinks \$drinkWord found for *\$query.",
  "Here's what we've got: \$numberOfDrinks \$drinkWord for *\$query.",
  "Great find! \$numberOfDrinks \$drinkWord available for *\$query.",
  "Take your pick! \$numberOfDrinks \$drinkWord for *\$query.",
  "I found \$numberOfDrinks \$drinkWord for *\$query. Let's choose one!",
  "We've got \$numberOfDrinks \$drinkWord for *\$query. What's your choice?",
  "Here's what I found: \$numberOfDrinks \$drinkWord for *\$query.",
  "Check out these \$numberOfDrinks \$drinkWord for *\$query.",
  "Here's a list of \$numberOfDrinks \$drinkWord for *\$query. Enjoy!",
  "We found \$numberOfDrinks \$drinkWord for *\$query. What do you think?",
  "There's a selection of \$numberOfDrinks \$drinkWord for *\$query.",
  "I found some options: \$numberOfDrinks \$drinkWord for *\$query.",
  "Great selection! \$numberOfDrinks \$drinkWord for *\$query.",
  "Here are \$numberOfDrinks \$drinkWord for *\$query. Let's pick one!",
  "You're all set with \$numberOfDrinks \$drinkWord for *\$query.",
  "We've got a selection of \$numberOfDrinks \$drinkWord for *\$query.",
  "Look what I found: \$numberOfDrinks \$drinkWord for *\$query.",
  "We've got \$numberOfDrinks \$drinkWord ready for *\$query.",
  "Check out the \$numberOfDrinks \$drinkWord we have for *\$query.",
  "Here's what you can choose from: \$numberOfDrinks \$drinkWord for *\$query.",
  "I've got \$numberOfDrinks \$drinkWord lined up for *\$query.",
  "We've got some great choices: \$numberOfDrinks \$drinkWord for *\$query.",
  "You're in luck! \$numberOfDrinks \$drinkWord for *\$query.",
  "There are \$numberOfDrinks \$drinkWord for *\$query. Let's explore!",
  "I've found \$numberOfDrinks \$drinkWord for *\$query. Ready?",
  "Here are \$numberOfDrinks \$drinkWord for *\$query. Enjoy choosing!",
  "We've got a great selection of \$numberOfDrinks \$drinkWord for *\$query.",
  "Take a look! \$numberOfDrinks \$drinkWord for *\$query.",
  "We found \$numberOfDrinks \$drinkWord for *\$query. Ready to choose?",
  "Here's a list: \$numberOfDrinks \$drinkWord for *\$query.",
  "You've got \$numberOfDrinks \$drinkWord for *\$query to pick from.",
  "We've got plenty of choices: \$numberOfDrinks \$drinkWord for *\$query.",
  "Here are some options: \$numberOfDrinks \$drinkWord for *\$query.",
  "Here's what we have: \$numberOfDrinks \$drinkWord for *\$query.",
  "Good news! \$numberOfDrinks \$drinkWord available for *\$query.",
  "You're in for a treat! \$numberOfDrinks \$drinkWord for *\$query.",
  "Check out these options: \$numberOfDrinks \$drinkWord for *\$query.",
  "We have \$numberOfDrinks \$drinkWord for *\$query. Take a look!",
  "Here's a great selection: \$numberOfDrinks \$drinkWord for *\$query.",
  "I found \$numberOfDrinks \$drinkWord for *\$query. Let's dive in!",
  "You're in luck! \$numberOfDrinks \$drinkWord for *\$query.",
  "Here are some choices: \$numberOfDrinks \$drinkWord for *\$query.",
  "We've got a great lineup: \$numberOfDrinks \$drinkWord for *\$query.",
  "Here's what I found: \$numberOfDrinks \$drinkWord for *\$query."
  ];


   static List<String> genericSingularPositiveResponses = [
  "Got it! Enjoy your drink!",
  "Cheers! This one's a great choice!",
  "Here's your drink, enjoy!",
  "Perfect pick! Enjoy every sip!",
  "Here's to a great choice, enjoy!",
  "One drink coming right up! Cheers!",
  "Here you go, enjoy your drink!",
  "Fantastic choice, enjoy!",
  "Enjoy your drink! Cheers!",
  "Here's a perfect match for you, enjoy!",
  "You've got good taste! Enjoy!",
  "Enjoy your drink, it's a good one!",
  "Here's something special, cheers!",
  "Here's what you asked for, enjoy!",
  "A perfect selection, enjoy!",
  "Sip and enjoy!",
  "Here's your order, enjoy!",
  "Here's your drink, cheers!",
  "Enjoy your choice!",
  "Here's your drink, bottoms up!",
  "Cheers! Enjoy your selection!",
  "This one's for you, enjoy!",
  "Enjoy the drink!",
  "Cheers! Enjoy every drop!",
  "Here's to a good time, enjoy!",
  "A great choice, enjoy!",
  "Enjoy your drink, it's a great pick!",
  "Here's to your good taste, enjoy!",
  "Drink up and enjoy!",
  "Here it is, enjoy!",
  "Your drink's ready, enjoy!",
  "Cheers to a great drink!",
  "Enjoy your selection!",
  "This one's a winner, enjoy!",
  "A fine choice, enjoy!",
  "Here's to you, enjoy your drink!",
  "Enjoy your drink, cheers!",
  "Here's your drink, enjoy it!",
  "Cheers to your selection!",
  "Enjoy your drink, it's a good one!",
  "Here's something nice, enjoy!",
  "A great pick, enjoy!",
  "Enjoy your drink, you've earned it!",
  "Here's a good one, enjoy!",
  "Drink up, enjoy!",
  "Here's your drink, bottoms up!",
  "Here's to a great choice, cheers!",
  "Enjoy the drink, it's a good one!",
  "Here's your selection, enjoy!",
  "Cheers! Enjoy the drink!"
];




    static String generateNegativeResponse(String query) {
    final randomIndex = _random.nextInt(genericNegativeResponses.length);
    // Replace placeholders with actual query
    return genericNegativeResponses[randomIndex].replaceAll('\$query', query);
  }

   static String generatePositiveResponse(int numberOfDrinks, String query) {
    final randomIndex = _random.nextInt(
      numberOfDrinks == 1 ? genericSingularPositiveResponses.length : genericPositiveResponses.length,
    );
    String drinkWord = numberOfDrinks == 1 ? "drink" : "drinks";

    String response = numberOfDrinks == 1
        ? genericSingularPositiveResponses[randomIndex]
        : genericPositiveResponses[randomIndex];

    return response
        .replaceAll('\$numberOfDrinks', numberOfDrinks.toString())
        .replaceAll('\$drinkWord', drinkWord)
        .replaceAll('\$query', query);
  }

  void addNegativeResponse(User user, String barId, String query) {
    String response = generateNegativeResponse(query);
    // print("addNegativeResponse: Adding response \"$response\" to history for barId $barId");
    user.addResponseToHistory(barId, response);
  }

  void addPositiveResponse(
      User user, String barId, int numberOfDrinks, String query) {
    String response = generatePositiveResponse(numberOfDrinks, query);
    user.addResponseToHistory(barId, response);
  }
}
