// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:megrim/UI/AuthPages/components/toggle.dart';
import 'package:megrim/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();
  final verificationCodeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  bool isVerificationCodeEnabled = false;
  bool isNewPasswordEnabled = false;
  bool isSubmitEmailDisabled = false;
  bool isVerificationSuccess = false;
  bool isSubmitButtonEnabled = true; // Manage submit button state

  @override
  void initState() {
    super.initState();
    // Automatically focus the email text field when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailFocusNode.requestFocus();
    });
  }

  Future<void> notifyServerEmailNeedsReset() async {
    setState(() {
      isSubmitButtonEnabled =
          false; // Disable submit button during email submission
    });

    final url = Uri.parse(
        '${AppConfig.postgresHttpBaseUrl}/auth/reset-password-validate-email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'action': 'checkEmail', 'email': emailController.text.trim()}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isVerificationCodeEnabled = true;
        isSubmitEmailDisabled = true; // Disable email field
        isSubmitButtonEnabled =
            true; // Re-enable submit button for the next step
      });

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          content: Center(
            child: Text(
              'Verification code sent to your email. Check your Spam/Junk folder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      setState(() {
        isSubmitButtonEnabled = true; // Re-enable submit button on failure
      });

      // Show alert dialog with error message from the response body
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
              response.body), // Show the error message from the response body
        ),
      );
    }
  }

  Future<void> checkVerificationCode() async {
    setState(() {
      isSubmitButtonEnabled =
          false; // Disable submit button during verification
    });

    final url = Uri.parse(
        '${AppConfig.postgresHttpBaseUrl}/auth/reset-password-validate-code');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'checkCode',
        'email': emailController.text.trim(),
        'code': verificationCodeController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        isVerificationSuccess = true;
        isVerificationCodeEnabled =
            false; // Grey out the verification code field
        isNewPasswordEnabled = true; // Enable password fields
        isSubmitButtonEnabled = true; // Re-enable submit button
      });
    } else {
      setState(() {
        isVerificationSuccess = false;
        isVerificationCodeEnabled = true; // Re-enable the verification field
        isSubmitButtonEnabled = true; // Re-enable submit button
      });

      // Display AlertDialog with the response body message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Code'),
          content: Text(
              'Error: ${response.body}'), // Display response body in the dialog
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Validate password and confirm password
  bool checkValidInput() {
    if (newPasswordController.text.length <= 6) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('Password must be at least 7 characters long.'),
        ),
      );
      return false;
    } else if (newPasswordController.text != confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('Passwords do not match.'),
        ),
      );
      return false;
    }
    return true;
  }

// Submit new password
  Future<void> newPassword() async {
    // Check if input is valid before proceeding
    if (!checkValidInput()) {
      return;
    }

    final url =
        Uri.parse('${AppConfig.postgresHttpBaseUrl}/auth/reset-password-final');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'resetPW',
        'email': emailController.text.trim(),
        'code': verificationCodeController.text.trim(),
        'password': newPasswordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      // If the response is successful, navigate to the LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginOrRegisterPage()), // Navigate to LoginPage
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Successfully reset password',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // If the response is unsuccessful, show the error message in an AlertDialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
              response.body), // Show the error message from the response body
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Forgot Password',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const LoginOrRegisterPage()), // Your LoginPage
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            TextField(
              controller: emailController,
              focusNode: emailFocusNode,
              cursorColor: Colors.white, // Change cursor color
              style: const TextStyle(
                color: Colors.white, // Change text color
                fontSize: 14, // Adjust text size if needed
              ),
              enabled: !isSubmitEmailDisabled,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Colors.grey, // Default label color
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: verificationCodeController,
              cursorColor: Colors.white, // Change cursor color
              style: const TextStyle(
                color: Colors.white, // Change text color
                fontSize: 14, // Adjust text size if needed
              ),
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                labelStyle: TextStyle(
                  color: Colors.grey, // Default label color
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number, // Numeric input only
              enabled: isVerificationCodeEnabled,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              cursorColor: Colors.white, // Change cursor color
              style: const TextStyle(
                color: Colors.white, // Change text color
                fontSize: 14, // Adjust text size if needed
              ),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: Colors.grey, // Default label color
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: isNewPasswordEnabled,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              cursorColor: Colors.white, // Change cursor color
              style: const TextStyle(
                color: Colors.white, // Change text color
                fontSize: 14, // Adjust text size if needed
              ),
              decoration: const InputDecoration(
                labelText: 'New Password Again',
                labelStyle: TextStyle(
                  color: Colors.grey, // Default label color
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: isNewPasswordEnabled,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: isSubmitButtonEnabled
                    ? () async {
                        if (!isSubmitEmailDisabled) {
                          await notifyServerEmailNeedsReset();
                        } else if (!isNewPasswordEnabled) {
                          // showDialog(
                          //   context: context,
                          //   builder: (context) => const AlertDialog(
                          //     title: Text('Verifying code...'),
                          //   ),
                          // );
                          await checkVerificationCode();
                        } else {
                          if (checkValidInput()) {
                            // showDialog(
                            //   context: context,
                            //   builder: (context) => const AlertDialog(
                            //     title: Text('Changing Password...'),
                            //   ),
                            // );
                            await newPassword();
                          }
                        }
                      }
                    : null, // Disable button if not enabled
                child:
                    const Text('Submit', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
