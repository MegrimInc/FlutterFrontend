import 'dart:convert';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/main.dart';
import 'package:flutter/material.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables to store user information
  String email = '';
  String password = '';
  int userId = 0;
  String firstName = '';
  String lastName = '';
  bool isEditing = false;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final FocusNode firstNameFocus = FocusNode(); // Focus node for first name
  final FocusNode lastNameFocus = FocusNode(); // Focus node for last name
  bool isTextFieldActive = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Add listeners to focus nodes
    firstNameFocus.addListener(() {
      setState(() {
        isTextFieldActive = firstNameFocus.hasFocus || lastNameFocus.hasFocus;
      });
    });
    lastNameFocus.addListener(() {
      setState(() {
        isTextFieldActive = firstNameFocus.hasFocus || lastNameFocus.hasFocus;
      });
    });
  }

  // Function to load user information from shared preferences
  void _loadUserInfo() async {
    final loginData = LoginCache();
    final loadedEmail = await loginData.getEmail();
    final loadedPassword = await loginData.getPW();
    final loadedUserId = await loginData.getUID();

    setState(() {
      email = loadedEmail;
      password = loadedPassword;
      userId = loadedUserId;
    });

    _fetchUserName(loadedUserId);
  }

  Future<void> _fetchUserName(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.barzzy.site/customer/getNames/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          firstName = responseData['firstName'] ?? '';
          lastName = responseData['lastName'] ?? '';
        });
      } else {
        debugPrint(
            'Failed to fetch user name. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  Future<void> _showStripeSetupSheet(BuildContext context, int userId) async {
    try {
      // Call your backend to create a SetupIntent and retrieve the client secret
      final response = await http.get(
        Uri.parse('https://www.barzzy.site/customer/createSetupIntent/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final setupIntentClientSecret = responseData["setupIntentClientSecret"];
        final customerId = responseData["customerId"];
        final setupIntentId = setupIntentClientSecret.split('_secret_')[0];
        debugPrint('SetupIntent Response Body: ${response.body}');

        // Initialize the payment sheet with the SetupIntent
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: setupIntentClientSecret,
            customerId: customerId,
            merchantDisplayName: "Barzzy",
            style: ThemeMode.system,
            allowsDelayedPaymentMethods: true, // Required for Apple Pay
            applePay: const PaymentSheetApplePay(
              merchantCountryCode: 'US',
            ),
          ),
        );

        // Present the Stripe payment sheet to collect and save payment info
        await Stripe.instance.presentPaymentSheet();
        await _savePaymentMethodToDatabase(userId, customerId, setupIntentId);
      } else {
        debugPrint(
            "Failed to load setup intent data. Status code: ${response.statusCode}");
        debugPrint("Error Response Body: ${response.body}");
        throw Exception(
            "Failed to load setup intent data with status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error presenting Stripe setup sheet: $e');
    }
  }

// Private method to save the payment method to the database
  Future<void> _savePaymentMethodToDatabase(
      int userId, String customerId, String setupIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.barzzy.site/customer/addPaymentIdToDatabase'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customerId": userId, // userId is the customer ID for your app
          "stripeId": customerId, // Stripe customer ID returned by Stripe
          "setupIntentId": setupIntentId // SetupIntent ID from Stripe
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Payment method successfully saved to database.");
      } else {
        debugPrint(
            "Failed to save payment method. Status code: ${response.statusCode}");
        debugPrint("Error Response Body: ${response.body}");
        throw Exception("Failed to save payment method to database.");
      }
    } catch (e) {
      debugPrint('Error saving payment method to database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            //const Spacer(flex: 3),

            const SizedBox(height: 50),
            // Profile Header
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const Spacer(flex: 2),

            Center(
              child: Column(
                children: [
                  isEditing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: firstNameController
                                  ..text = firstName,
                                focusNode: firstNameFocus,
                                textAlign: TextAlign.center,
                                cursorColor: Colors.white,
                                decoration: const InputDecoration(
                                  hintText: 'First Name',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors
                                            .white), // Focus border color set to white
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: lastNameController..text = lastName,
                                focusNode: lastNameFocus,
                                textAlign: TextAlign.center,
                                cursorColor: Colors.white,
                                decoration: const InputDecoration(
                                  hintText: 'Last Name',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors
                                            .white), // Focus border color set to white
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '$firstName $lastName',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton(
                      onPressed: () {
                        if (isEditing) {
                          _updateUserName();
                          setState(() {
                           isTextFieldActive = false;
                          });
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      child: Text(
                        isEditing ? 'Save' : 'Edit',
                        style: const TextStyle(
                          color: Colors
                              .white54, // Text color set to white with 54% opacity
                          fontSize: 16, // Optional: Adjust font size if needed
                          fontWeight: FontWeight.bold, // Optional: Add emphasis
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Sectioned Tiles
              SizedBox(
                height: isTextFieldActive ? 100 : 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Payment Method',
                        subtitle: 'Update your payment method',
                        icon: Icons.credit_card,
                        onTap: () {
                          // Navigate to payment update
                          _showStripeSetupSheet(context, userId);
                        },
                      ),
                      if (!isTextFieldActive)
                      _buildTile(
                        title: 'Log Out',
                        subtitle: 'End your current session',
                        icon: Icons.exit_to_app,
                        onTap: () {
                          showConfirmationDialog(
                            context,
                            'Log Out',
                            () {
                              clearSharedPrefs();
                              navigatorKey.currentState?.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginOrRegisterPage()),
                                (route) => false,
                              );
                            },
                          );
                        },
                      ),
                      if (!isTextFieldActive)
                      _buildTile(
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        icon: Icons.delete_forever,
                        onTap: () {
                          // Account deletion confirmation
                          showConfirmationDialog(
                            context,
                            'Delete Account',
                            deleteAccount,
                          );
                        },
                        tileColor: Colors.redAccent.withOpacity(0.2),
                        iconColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

// Reusable Tile Widget
  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color tileColor = Colors.white10,
    Color iconColor = Colors.grey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserName() async {
    final requestBody = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://www.barzzy.site/customer/updateNames/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          firstName = data['firstName'];
          lastName = data['lastName'];
          isEditing = false; // Exit edit mode
        });
      } else {
        debugPrint('Failed to update user name: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating user name: $e');
    }
  }

  // Function to delete user account and log out
  Future<void> deleteAccount() async {
    final response = await http.post(
      Uri.parse('https://www.barzzy.site/newsignup/deleteaccount'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      clearSharedPrefs(); // Clear preferences if account deletion is successful
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
    } else {
      debugPrint(
          'Error: ${response.statusCode}'); // Print error status code for debugging
      debugPrint(
          'Error body: ${response.body}'); // Print error body for debugging

      // Use the global navigator key to show the SnackBar
      final snackBarContext = navigatorKey.currentContext;

      if (snackBarContext != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(snackBarContext).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again later.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint('Error: Unable to show SnackBar. Context is null.');
      }
    }
  }

  // Function to clear shared preferences and log out
  void clearSharedPrefs() {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);
    final loginData = LoginCache();
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setUID(0);
    loginData.setSignedIn(false);
    hierarchy.disconnect();
    localDatabase.clearOrders();
  }

  // Show confirmation dialog
  void showConfirmationDialog(
      BuildContext context, String actionType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  actionType == 'Log Out'
                      ? Icons.exit_to_app
                      : Icons.delete_forever,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Text(
                  actionType == 'Log Out' ? 'Confirm Logout' : 'Confirm Delete',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            actionType == 'Log Out'
                ? 'Are you sure you want to log out?'
                : 'Are you sure you want to delete your account?',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            const SizedBox(width: 10),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                onConfirm(); // Call the confirmation action
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of controllers and focus nodes
    firstNameController.dispose();
    lastNameController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    super.dispose();
  }
}
