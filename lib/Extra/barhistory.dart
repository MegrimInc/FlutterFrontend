import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarHistory with ChangeNotifier {
  List<String> _historyIds = [];
  Function()? _updateSearchFeedCallback;
  List<String> get historyIds => _historyIds;
  final List<String> _pinnedBars = []; 

  
  // Adds a bar ID to the history, ensuring it's the first item if it already exists
  void addToHistory(String barId) {
    if (_historyIds.contains(barId)) {
      _historyIds.remove(barId);
    }
    _historyIds.insert(0, barId);
    if (_historyIds.length > 6) {
      _historyIds.removeLast();
    }
    notifyListeners();
    saveHistoryToLocalStorage();
    if (_updateSearchFeedCallback != null) {
      _updateSearchFeedCallback!();
    }
  }

List<String> getHistoryInOrder() {
    return List.from(_historyIds.reversed);
  }


  // Saves the current state of the history to local storage
  void saveHistoryToLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bar_history', _historyIds);
  }

  // Loads the history from local storage upon initialization or as needed
  void loadHistoryFromLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _historyIds = prefs.getStringList('bar_history') ?? [];
    notifyListeners();
  }

void setUpdateSearchFeedCallback(Function() callback) {
    _updateSearchFeedCallback = callback;
  }


  //PIN LOGIC

  // Pin a bar
  void pinBar(String barId) {
    _pinnedBars.add(barId);
    notifyListeners();
  }

  // Unpin a bar
  void unpinBar(String barId) {
    _pinnedBars.remove(barId);
    notifyListeners();
  }

  // Check if a bar is pinned
  bool isBarPinned(String barId) {
    return _pinnedBars.contains(barId);
  }





}
