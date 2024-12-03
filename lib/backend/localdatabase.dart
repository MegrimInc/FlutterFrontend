import 'dart:async';

import 'package:barzzy/Backend/customer_order.dart';
import 'package:barzzy/Backend/tags.dart';

import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/point.dart';

import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'bar.dart';

class LocalDatabase with ChangeNotifier {
  static final LocalDatabase _singleton = LocalDatabase._internal();

  factory LocalDatabase() {
    return _singleton;
  }

  LocalDatabase._internal() {
    Timer.periodic(const Duration(minutes: 10, seconds: 0), (Timer timer) {
      _updateAndCheckHappyHourStatus();
    });
  }

  final Map<String, Bar> _bars = {};
  final Map<String, Tag> tags = {};
  final Map<String, Drink> _drinks = {};
  final Map<String, CustomerOrder> _barOrders = {};
  final Map<String, Point> _userPoints = {};
  final Map<String, bool> _happyHourStatusMap = {};
   bool isPaymentPresent = false;
   

    void updatePaymentStatus(bool status) {
    isPaymentPresent = status;
    notifyListeners();
  }


  void addOrUpdateOrderForBar(CustomerOrder order) {
    _barOrders[order.barId] = order;
    notifyListeners();
  }

  CustomerOrder? getOrderForBar(String barId) {
    return _barOrders[barId];
  }

  // Method to add a new bar, generating an ID for it
  void addBar(Bar bar) {
    if (bar.id != null) {
      _bars[bar.id!] = bar;
      _checkHappyHourForBar(bar.id!);
      notifyListeners();
      debugPrint(
          'Bar with ID: ${bar.id} added by LocalDatabase instance: $hashCode.');
    } else {
      debugPrint('Bar ID is null, cannot add to database.');
    }
  }

  void addDrink(Drink drink) {
    _drinks[drink.id] = drink;
    notifyListeners();
    debugPrint(
        'Drink with ID: ${drink.id} added to LocalDatabase instance: $hashCode. Total drinks: ${_drinks.length}');
  }

  void addTag(Tag tag) {
    tags[tag.id] = tag;
    notifyListeners();
  }

  // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableBarInfo() {
    return _bars.map((id, bar) =>
        MapEntry(id, {'name': bar.name ?? '', 'address': bar.address ?? ''}));
  }

  //Method to get all bar IDs
  List<String> getAllBarIds() {
    return _bars.keys.toList();
  }

  static Bar? getBarById(String id) {
    return _singleton._bars[id];
  }

  Drink getDrinkById(String id) {
    debugPrint('Drink found for ID: $id in LocalDatabase instance: $hashCode');
    return _drinks[id]!;
  }

  void clearOrders() {
    _barOrders.clear();
    notifyListeners();
    debugPrint("All orders have been cleared.");
    _userPoints.clear();
    debugPrint("All points have been cleared.");
  }

  void addOrUpdatePoints(String barId, int points) {
    _userPoints[barId] = Point(barId: barId, points: points);
    notifyListeners();
    debugPrint('Points updated for bar $barId: $points points');
  }

  // Method to get points for a specific bar
  Point? getPointsForBar(String barId) {
    return _userPoints[barId];
  }

  // Method to get all points for the user
  Map<String, Point> getAllPoints() {
    return _userPoints;
  }

  void clearPoints() {
    _userPoints.clear();
    notifyListeners();
    debugPrint('All points have been cleared.');
  }

  void _updateAndCheckHappyHourStatus() async {
    try {
      // Fetch the current UTC time from an NTP server
      DateTime now = (await NTP.now()).toUtc();
      debugPrint("Current NTP UTC time: $now");

      bool anyChanges = false;

      _bars.forEach((barId, bar) {
        if (bar.happyHours != null) {
          String dayOfWeek = [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ][now.weekday % 7];

          String? todayHappyHours = bar.happyHours![dayOfWeek];
          bool isHappyHourNow = false;

          if (todayHappyHours != null) {
            debugPrint(
                "Today's ($dayOfWeek) happy hours for bar ID $barId: $todayHappyHours");
            List<String> timeRanges = todayHappyHours.split(" | ");

            for (var range in timeRanges) {
              List<String> hours = range.split(" - ");
              List<int> startTime =
                  hours[0].split(":").map((e) => int.parse(e)).toList();
              List<int> endTime =
                  hours[1].split(":").map((e) => int.parse(e)).toList();

              DateTime start = DateTime.utc(
                now.year,
                now.month,
                now.day,
                startTime[0],
                startTime[1],
              );

              DateTime end = DateTime.utc(
                now.year,
                now.month,
                now.day,
                endTime[0],
                endTime[1],
              );

              debugPrint(
                  "Checking range - Bar ID: $barId - Happy hour UTC start: $start, end: $end");

              if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                  (now.isBefore(end) || now.isAtSameMomentAs(end))) {
                isHappyHourNow = true;
                debugPrint("Bar $barId is within happy hour range.");
                break;
              }
            }
          }

          if (!isHappyHourNow) {
            debugPrint("Bar ID: $barId is NOT within any happy hour range.");
          }

          // Update happy hour status if it has changed
          if (_happyHourStatusMap[barId] != isHappyHourNow) {
            _happyHourStatusMap[barId] = isHappyHourNow;
            anyChanges = true;
            debugPrint(
                "Happy hour status updated for Bar $barId to: $isHappyHourNow");
          }
        }
      });

      if (anyChanges) {
        notifyListeners();
        debugPrint("Happy hour status updated for one or more bars.");
      }
    } catch (e) {
      debugPrint("Failed to fetch NTP time: $e");
    }
  }

  // New function to check happy hour status for a specific bar
  Future<void> _checkHappyHourForBar(String barId) async {
    DateTime now = (await NTP.now()).toUtc();
    debugPrint("Checking happy hour status for bar $barId at time $now");

    bool isHappyHourNow = false;
    final bar = _bars[barId];

    if (bar?.happyHours != null) {
      String dayOfWeek = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ][now.weekday % 7];

      String? todayHappyHours = bar!.happyHours![dayOfWeek];
      if (todayHappyHours != null) {
        List<String> timeRanges = todayHappyHours.split(" | ");

        for (var range in timeRanges) {
          List<String> hours = range.split(" - ");
          List<int> startTime = hours[0].split(":").map(int.parse).toList();
          List<int> endTime = hours[1].split(":").map(int.parse).toList();

          DateTime start = DateTime.utc(
            now.year,
            now.month,
            now.day,
            startTime[0],
            startTime[1],
          );

          DateTime end = DateTime.utc(
            now.year,
            now.month,
            now.day,
            endTime[0],
            endTime[1],
          );

          if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
              (now.isBefore(end) || now.isAtSameMomentAs(end))) {
            isHappyHourNow = true;
            debugPrint("Bar $barId is within happy hour range.");
            break;
          }
        }
      }
    }

    // Update the happy hour status map and notify if there was a change
    if (_happyHourStatusMap[barId] != isHappyHourNow) {
      _happyHourStatusMap[barId] = isHappyHourNow;
      notifyListeners();
      debugPrint(
          "Happy hour status updated for bar $barId to: $isHappyHourNow");
    }
  }

  bool isBarInHappyHour(String barId) {
    return _happyHourStatusMap[barId] ?? false;
  }
}
