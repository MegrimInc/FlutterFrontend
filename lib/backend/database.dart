import 'dart:async';
import 'dart:convert';

import 'package:megrim/DTO/category.dart';
import 'package:megrim/DTO/config.dart';
import 'package:megrim/DTO/customer.dart';
import 'package:megrim/DTO/customerorder.dart';
import 'package:megrim/DTO/item.dart';
import 'package:megrim/DTO/point.dart';
import 'package:megrim/config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import '../DTO/merchant.dart';
import 'package:http/http.dart' as http;

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
      updateAndCheckDiscountScheduleStatus();
  }

  final Map<int, Merchant> _merchants = {};
  final Map<int, Item> _items = {};
  final Map<int, CustomerOrder> _merchantOrders = {};
  final Map<int, Point> _customerPoints = {};
  final Map<int, bool> _discountScheduleMap = {};
  bool isPaymentPresent = false;
  final Map<int, Map<String, List<int>>> categoryMap = {};
  final Map<int, Category> _categoriesById = {};
  Config? _config;
  PaymentStatus paymentStatus = PaymentStatus.notPresent;
  Config? get config => _config;


void setConfig(Config config) {
  _config = config;
  notifyListeners();
  debugPrint("Configuration updated: $config");
}

  void updatePaymentStatus(PaymentStatus status) {
    paymentStatus = status;
    notifyListeners();
    debugPrint('Payment status updated to: $status');
  }

  void addOrUpdateOrderForMerchant(CustomerOrder order) {
    _merchantOrders[order.merchantId] = order;
    notifyListeners();
  }

  CustomerOrder? getOrderForMerchant(int merchantId) {
    return _merchantOrders[merchantId];
  }

  // Method to add a new merchant, generating an Id for it
  void addMerchant(Merchant merchant) {
    if (merchant.merchantId != null) {
      _merchants[merchant.merchantId!] = merchant;
      _checkDiscountScheduleForMerchant(merchant.merchantId!);
      notifyListeners();
      debugPrint(
          'Merchant with Id: ${merchant.merchantId} added by LocalDatabase instance: $hashCode.');
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
  Map<int, Map<String, String>> getSearchableMerchantInfo() {
    return _merchants.map((id, merchant) =>
        MapEntry(id, {'name': merchant.name ?? '', 'address': merchant.address ?? ''}));
  }

  // In LocalDatabase class
  Map<int, Merchant> get merchants => _merchants;

  //Method to get all merchant Ids
  List<int> getAllMerchantIds() {
    return _merchants.keys.toList();
  }

  static Merchant? getMerchantById(int id) {
    return _singleton._merchants[id];
  }

  Item getItemById(int id) {
    return _items[id]!;
  }

  void clearOrders() {
    _merchantOrders.clear();
    notifyListeners();
    debugPrint("All orders have been cleared.");
    _customerPoints.clear();
    debugPrint("All points have been cleared.");
  }

  void addOrUpdatePoints(int merchantId, int points) {
    _customerPoints[merchantId] = Point(merchantId: merchantId, points: points);
    notifyListeners();
    debugPrint('Points updated for merchant $merchantId: $points points');
  }

  // Method to get points for a specific merchant
  Point? getPointsForMerchant(int merchantId) {
    return _customerPoints[merchantId];
  }

  // Method to get all points for the customer
  Map<int, Point> getAllPoints() {
    return _customerPoints;
  }

  void clearPoints() {
    _customerPoints.clear();
    notifyListeners();
    debugPrint('All points have been cleared.');
  }

  void updateAndCheckDiscountScheduleStatus() async {
    try {
      // Fetch the current UTC time from an NTP server
      DateTime now = (await NTP.now()).toUtc();
      debugPrint("Current NTP UTC time: $now");

      bool anyChanges = false;

      _merchants.forEach((merchantId, merchant) {
        if (merchant.discountSchedule != null) {
          String dayOfWeek = [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ][now.weekday % 7];

          String? todayDiscountSchedule = merchant.discountSchedule![dayOfWeek];
          bool isDiscount = false;

          if (todayDiscountSchedule != null) {
            debugPrint(
                "Today's ($dayOfWeek) Discount Schedules for merchant Id $merchantId: $todayDiscountSchedule");
            List<String> timeRanges = todayDiscountSchedule.split(" | ");

            for (var range in timeRanges) {
              List<String> schedule = range.split(" - ");
              List<int> startTime =
                  schedule[0].split(":").map((e) => int.parse(e)).toList();
              List<int> endTime =
                  schedule[1].split(":").map((e) => int.parse(e)).toList();

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
                  "Checking range - Merchant Id: $merchantId - Discount Schedule UTC start: $start, end: $end");

              if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                  (now.isBefore(end) || now.isAtSameMomentAs(end))) {
                isDiscount = true;
                debugPrint("Merchant $merchantId is within Discount Schedule range.");
                break;
              }
            }
          }

          if (!isDiscount) {
            debugPrint("Merchant Id: $merchantId is NOT within any Discount Schedule range.");
          }

          // Update Discount Schedule status if it has changed
          if (_discountScheduleMap[merchantId] != isDiscount) {
            _discountScheduleMap[merchantId] = isDiscount;
            anyChanges = true;
            debugPrint(
                "Discount Schedule status updated for Merchant $merchantId to: $isDiscount");
          }
        }
      });

      if (anyChanges) {
        notifyListeners();
        debugPrint("Discount Schedule status updated for one or more merchants.");
      }
    } catch (e) {
      debugPrint("Failed to fetch NTP time: $e");
    }
  }

  // New function to check Discount Schedule status for a specific merchant
  Future<void> _checkDiscountScheduleForMerchant(int merchantId) async {
    DateTime now = (await NTP.now()).toUtc();
    debugPrint("Checking Discount Schedule status for merchant $merchantId at time $now");

    bool isDiscount = false;
    final merchant = _merchants[merchantId];

    if (merchant?.discountSchedule != null) {
      String dayOfWeek = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ][now.weekday % 7];

      String? todayDiscountSchedule = merchant!.discountSchedule![dayOfWeek];
      if (todayDiscountSchedule != null) {
        List<String> timeRanges = todayDiscountSchedule.split(" | ");

        for (var range in timeRanges) {
          List<String> schedule = range.split(" - ");
          List<int> startTime = schedule[0].split(":").map(int.parse).toList();
          List<int> endTime = schedule[1].split(":").map(int.parse).toList();

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
            isDiscount = true;
            debugPrint("Merchant $merchantId is within Discount Schedule range.");
            break;
          }
        }
      }
    }

    // Update the Discount Schedule status map and notify if there was a change
    if (_discountScheduleMap[merchantId] != isDiscount) {
      _discountScheduleMap[merchantId] = isDiscount;
      notifyListeners();
      debugPrint(
          "Discount Schedule status updated for merchant $merchantId to: $isDiscount");
    }
  }

  bool isMerchantInDiscountSchedule(int merchantId) {
    return _discountScheduleMap[merchantId] ?? false;
  }

   Customer? _customer;

  Customer? get customer => _customer;

  void setCustomer(Customer customer) {
    _customer = customer;
    notifyListeners();
    debugPrint("Customer data updated in LocalDatabase: $customer");
  }



/// Adds a single category
void addCategory(Category category) {
  _categoriesById[category.categoryId] = category;
}

void addCategories(int merchantId, Map<String, List<int>> categories) {
  categoryMap[merchantId] = categories;
  notifyListeners();
}

/// Adds a list of categories
void addCategoriesList(List<Category> categories) {
  for (final category in categories) {
    _categoriesById[category.categoryId] = category;
  }
}

/// Retrieves category name by its ID
String? getCategoryNameById(int categoryId) {
  return _categoriesById[categoryId]?.name;
}

/// Checks if categories are already loaded for a merchant
bool categoriesExistForMerchant(int merchantId) {
  return categoryMap.containsKey(merchantId);
}

/// Returns the full item list grouped by category name
Map<String, List<int>> getFullItemListByMerchantId(int merchantId) {
  return categoryMap[merchantId] ?? {};
}

/// Ensures a merchant is cached locally
Future<void> checkForMerchant(int merchantId) async {
  try {
    if (!_merchants.containsKey(merchantId)) {
      debugPrint("Merchant $merchantId not found locally. Fetching...");

      final response = await http.get(Uri.parse("${AppConfig.postgresHttpBaseUrl}/customer/$merchantId"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Merchant merchant = Merchant.fromJson(data);
        addMerchant(merchant);
        debugPrint("Merchant $merchantId added to local cache.");
      } else {
        throw Exception("Failed to fetch merchant: ${response.statusCode}");
      }
    }
  } catch (error) {
    debugPrint("Error fetching merchant $merchantId: $error");
  }
}

Future<void> fetchCategoriesAndItems(int merchantId) async {
  debugPrint('Fetching inventory for merchant $merchantId');
  await checkForMerchant(merchantId);

  if (categoriesExistForMerchant(merchantId)) {
    debugPrint('Categories already exist for merchant $merchantId, skipping.');
    return;
  }

  final response = await http.get(
    Uri.parse('${AppConfig.postgresHttpBaseUrl}/customer/getInventoryByMerchant/$merchantId'),
  );

  if (response.statusCode == 200) {
    debugPrint('Full JSON response from API: ${response.body}');
    final Map<String, dynamic> json = jsonDecode(response.body);

    final List<dynamic> itemJsonList = json['items'];
    final List<dynamic> categoryJsonList = json['categories'];

    final Map<String, List<int>> merchantCategories = {};

    // Load categories first so we can get names during item processing
    addCategoriesList(categoryJsonList.map((e) => Category(
      categoryId: e['categoryId'],
      name: e['name'],
    )).toList());

    for (var itemJson in itemJsonList) {
      final item = Item.fromJson(itemJson);
      addItem(item);

      debugPrint('Item ${item.itemId} added to LocalDatabase.');

      if (item.image.isNotEmpty) {
        final cachedImage = CachedNetworkImageProvider(item.image);
        cachedImage.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (image, _) => debugPrint('Cached image for ${item.image}'),
            onError: (e, _) => debugPrint('Failed to cache image: $e'),
          ),
        );
      }

      for (int categoryId in item.categories) {
        final categoryName = getCategoryNameById(categoryId);
        if (categoryName != null) {
          merchantCategories.putIfAbsent(categoryName, () => []).add(item.itemId);
        }
      }
    }

    addCategories(merchantId, merchantCategories);
    debugPrint('Completed categorization for merchant $merchantId.');
  } else {
    debugPrint('Failed to fetch inventory for $merchantId. Status: ${response.statusCode}');
  }
}

}