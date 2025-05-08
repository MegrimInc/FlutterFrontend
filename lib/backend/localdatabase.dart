import 'dart:async';

import 'package:barzzy/Backend/customer.dart';
import 'package:barzzy/Backend/customerorder.dart';
import 'package:barzzy/Backend/item.dart';
import 'package:barzzy/Backend/point.dart';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'merchant.dart';

enum PaymentStatus {
  loading,
  notPresent,
  present,
}

class LocalDatabase with ChangeNotifier {
  static final LocalDatabase _singleton = LocalDatabase._internal();

  factory LocalDatabase() {
    return _singleton;
  }

  LocalDatabase._internal() {
    Timer.periodic(const Duration(minutes: 30, seconds: 0), (Timer timer) {
      updateAndCheckHappyHourStatus();
    });
    
  }

  final Map<String, Merchant> _merchants = {};
  final Map<String, Item> _items = {};
  final Map<String, CustomerOrder> _merchantOrders = {};
  final Map<String, Point> _customerPoints = {};
  final Map<String, bool> _happyHourStatusMap = {};
  bool isPaymentPresent = false;

  PaymentStatus paymentStatus = PaymentStatus.notPresent;

  void updatePaymentStatus(PaymentStatus status) {
    paymentStatus = status;
    notifyListeners();
    debugPrint('Payment status updated to: $status');
  }

  void addOrUpdateOrderForMerchant(CustomerOrder order) {
    _merchantOrders[order.merchantId] = order;
    notifyListeners();
  }

  CustomerOrder? getOrderForMerchant(String merchantId) {
    return _merchantOrders[merchantId];
  }

  // Method to add a new merchant, generating an Id for it
  void addMerchant(Merchant merchant) {
    if (merchant.id != null) {
      _merchants[merchant.id!] = merchant;
      _checkHappyHourForMerchant(merchant.id!);
      notifyListeners();
      debugPrint(
          'Merchant with Id: ${merchant.id} added by LocalDatabase instance: $hashCode.');
    } else {
      debugPrint('Merchant Id is null, cannot add to database.');
    }
  }

  void addItem(Item item) {
    _items[item.itemId] = item;
    notifyListeners();
    debugPrint(
        'Item with Id: ${item.itemId} added to LocalDatabase instance: $hashCode. Total items: ${_items.length}');
  }


  // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableMerchantInfo() {
    return _merchants.map((id, merchant) =>
        MapEntry(id, {'name': merchant.name ?? '', 'address': merchant.address ?? ''}));
  }

  // In LocalDatabase class
  Map<String, Merchant> get merchants => _merchants;

  //Method to get all merchant Ids
  List<String> getAllMerchantIds() {
    return _merchants.keys.toList();
  }

  static Merchant? getMerchantById(String id) {
    return _singleton._merchants[id];
  }

  Item getItemById(String id) {
    debugPrint('Item found for Id: $id in LocalDatabase instance: $hashCode');
    return _items[id]!;
  }

  void clearOrders() {
    _merchantOrders.clear();
    notifyListeners();
    debugPrint("All orders have been cleared.");
    _customerPoints.clear();
    debugPrint("All points have been cleared.");
  }

  void addOrUpdatePoints(String merchantId, int points) {
    _customerPoints[merchantId] = Point(merchantId: merchantId, points: points);
    notifyListeners();
    debugPrint('Points updated for merchant $merchantId: $points points');
  }

  // Method to get points for a specific merchant
  Point? getPointsForMerchant(String merchantId) {
    return _customerPoints[merchantId];
  }

  // Method to get all points for the customer
  Map<String, Point> getAllPoints() {
    return _customerPoints;
  }

  void clearPoints() {
    _customerPoints.clear();
    notifyListeners();
    debugPrint('All points have been cleared.');
  }

  void updateAndCheckHappyHourStatus() async {
    try {
      // Fetch the current UTC time from an NTP server
      DateTime now = (await NTP.now()).toUtc();
      debugPrint("Current NTP UTC time: $now");

      bool anyChanges = false;

      _merchants.forEach((merchantId, merchant) {
        if (merchant.happyHours != null) {
          String dayOfWeek = [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ][now.weekday % 7];

          String? todayHappyHours = merchant.happyHours![dayOfWeek];
          bool isHappyHourNow = false;

          if (todayHappyHours != null) {
            debugPrint(
                "Today's ($dayOfWeek) happy hours for merchant Id $merchantId: $todayHappyHours");
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
                  "Checking range - Merchant Id: $merchantId - Happy hour UTC start: $start, end: $end");

              if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                  (now.isBefore(end) || now.isAtSameMomentAs(end))) {
                isHappyHourNow = true;
                debugPrint("Merchant $merchantId is within happy hour range.");
                break;
              }
            }
          }

          if (!isHappyHourNow) {
            debugPrint("Merchant Id: $merchantId is NOT within any happy hour range.");
          }

          // Update happy hour status if it has changed
          if (_happyHourStatusMap[merchantId] != isHappyHourNow) {
            _happyHourStatusMap[merchantId] = isHappyHourNow;
            anyChanges = true;
            debugPrint(
                "Happy hour status updated for Merchant $merchantId to: $isHappyHourNow");
          }
        }
      });

      if (anyChanges) {
        notifyListeners();
        debugPrint("Happy hour status updated for one or more merchants.");
      }
    } catch (e) {
      debugPrint("Failed to fetch NTP time: $e");
    }
  }

  // New function to check happy hour status for a specific merchant
  Future<void> _checkHappyHourForMerchant(String merchantId) async {
    DateTime now = (await NTP.now()).toUtc();
    debugPrint("Checking happy hour status for merchant $merchantId at time $now");

    bool isHappyHourNow = false;
    final merchant = _merchants[merchantId];

    if (merchant?.happyHours != null) {
      String dayOfWeek = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ][now.weekday % 7];

      String? todayHappyHours = merchant!.happyHours![dayOfWeek];
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
            debugPrint("Merchant $merchantId is within happy hour range.");
            break;
          }
        }
      }
    }

    // Update the happy hour status map and notify if there was a change
    if (_happyHourStatusMap[merchantId] != isHappyHourNow) {
      _happyHourStatusMap[merchantId] = isHappyHourNow;
      notifyListeners();
      debugPrint(
          "Happy hour status updated for merchant $merchantId to: $isHappyHourNow");
    }
  }

  bool isMerchantInHappyHour(String merchantId) {
    return _happyHourStatusMap[merchantId] ?? false;
  }

   Customer? _customer;

  Customer? get customer => _customer;

  void setCustomer(Customer customer) {
    _customer = customer;
    notifyListeners();
    debugPrint("Customer data updated in LocalDatabase: $customer");
  }

}