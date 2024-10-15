import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:flutter/material.dart';

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
  bool isVerifying = false;

  // Placeholder functions
  void notifyServerEmailNeedsReset() {
    debugPrint('Request to reset password sent for: ${emailController.text}');
  }

  void checkVerificationCode(String email, String code) {
    debugPrint('Verifying code $code for email $email...');
    setState(() {
      isVerifying = true;
    });

    // Simulate backend response delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isVerifying = false;
        if (code == "123456") { // Simulated correct code
          isVerificationSuccess = true;
          isVerificationCodeEnabled = false; // Lock the verification field
          isNewPasswordEnabled = true; // Enable password fields
        } else {
          isVerificationSuccess = false;
        }
      });
    });
  }

  bool checkValidInput() {
    final passwordPattern = RegExp(r'^[a-zA-Z0-9_]+$');
    return passwordPattern.hasMatch(newPasswordController.text);
  }

  void newPassword() {
    debugPrint('Setting new password...');
    Future.delayed(const Duration(seconds: 2), () {
      bool resetSuccess = newPasswordController.text == confirmPasswordController.text;
      if (resetSuccess) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()), // Navigate to LoginPage
          (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successful password reset')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed password reset')),
        );
      }
    });
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
              onPressed: () {
                if (!isSubmitEmailDisabled) {
                  notifyServerEmailNeedsReset();
                  setState(() {
                    isVerificationCodeEnabled = true;
                    isSubmitEmailDisabled = true;
                  });
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Notification'),
                      content: Text(
                          'If your email exists, a verification code has been sent. Check your Spam/Junk folder!'),
                    ),
                  );
                } else if (!isNewPasswordEnabled) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Verifying code...'),
                    ),
                  );
                  checkVerificationCode(
                    emailController.text.trim(),
                    verificationCodeController.text.trim(),
                  );
                } else {
                  if (checkValidInput()) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        title: Text('Changing Password...'),
                      ),
                    );
                    newPassword();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        title: Text('Error'),
                        content: Text(
                            'Passwords can only contain a-z, A-Z, 0-9, and underscores'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
