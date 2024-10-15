import 'dart:convert';
import 'package:barzzy/AuthPages/components/toggle.dart';
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

  bool isVerificationCodeEnabled = false;
  bool isNewPasswordEnabled = false;
  bool isSubmitEmailDisabled = false;
  bool isVerificationSuccess = false;
  bool isSubmitButtonEnabled = true;  // Manage submit button state

  // Notify server to reset email
  Future<void> notifyServerEmailNeedsReset() async {
    final url = Uri.parse('https://www.barzzy.site/newsignup/reset-password-validate-email');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailController.text.trim()}),
    );

    setState(() {
      isVerificationCodeEnabled = true;
      isSubmitEmailDisabled = true;
    });

    // Snackbar to notify verification code is sent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code sent to your email. Check your Spam/Junk folder.'),
      ),
    );
  }

  // Check verification code
  Future<void> checkVerificationCode() async {
    setState(() {
      isSubmitButtonEnabled = false; // Disable submit button during verification
    });

    final url = Uri.parse('https://www.barzzy.site/newsignup/reset-password-validate-code');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'code': verificationCodeController.text.trim(),
      }),
    );

    // Snackbar while verifying code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking code...')),
    );

    if (response.statusCode == 200) {
      setState(() {
        isVerificationSuccess = true;
        isVerificationCodeEnabled = false; // Grey out the verification code field
        isNewPasswordEnabled = true; // Enable password fields
        isSubmitButtonEnabled = true; // Re-enable submit button
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code verified!')),
      );
    } else {
      setState(() {
        isVerificationSuccess = false;
        isVerificationCodeEnabled = true; // Re-enable the verification field
        isSubmitButtonEnabled = true; // Re-enable submit button
      });

      // AlertDialog to notify invalid code
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Invalid Code'),
          content: Text('Verification code is incorrect. Please try again.'),
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
    if (!checkValidInput()) {
      return;
    }

    final url = Uri.parse('https://www.barzzy.site/newsignup/reset-password-final');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'code': verificationCodeController.text.trim(),
        'password': newPasswordController.text.trim(),
      }),
    );

    // Navigate to LoginPage and show a success snackbar
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()), // Navigate to LoginPage
      (Route<dynamic> route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully reset password')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()), // Your LoginPage
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
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !isSubmitEmailDisabled,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: verificationCodeController,
              decoration: const InputDecoration(labelText: 'Verification Code'),
              keyboardType: TextInputType.number, // Numeric input only
              enabled: isVerificationCodeEnabled,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
              enabled: isNewPasswordEnabled,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'New Password Again'),
              obscureText: true,
              enabled: isNewPasswordEnabled,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitButtonEnabled ? () async {
                if (!isSubmitEmailDisabled) {
                  await notifyServerEmailNeedsReset();
                } else if (!isNewPasswordEnabled) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Verifying code...'),
                    ),
                  );
                  await checkVerificationCode();
                } else {
                  if (checkValidInput()) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        title: Text('Changing Password...'),
                      ),
                    );
                    await newPassword();
                  }
                }
              } : null, // Disable button if not enabled
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
