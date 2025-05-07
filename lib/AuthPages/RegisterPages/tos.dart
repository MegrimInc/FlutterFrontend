// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/Gnav%20Bar/bottombar.dart';
import 'package:barzzy/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class RegisterPage2 extends StatefulWidget {
  const RegisterPage2({super.key});

  @override
  State<RegisterPage2> createState() => _RegisterPageState2();
}

class _RegisterPageState2 extends State<RegisterPage2> {
  final ScrollController _scrollController = ScrollController();
  //bool _isAtEndOfPage = false;

  @override
  void initState() {
    super.initState();
    //_scrollController.addListener(_onScroll);
  }

  void acceptTOS() async {
    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/auth/accept-tos');
    final loginCache8 = LoginCache();
    final tosEmail = await loginCache8.getEmail();

    final requestBody = jsonEncode({'email': tosEmail});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        debugPrint('TOS Request successful');
        debugPrint('TOS Response body: ${response.body}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      } else {
        debugPrint('TOS Request failed with status: ${response.statusCode}');
        debugPrint('TOS Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      failure();
    }
  }

  void failure() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Colors.black,
          title: Center(
            child: Text(
              'Something went wrong. Please try again later.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: GestureDetector(
          onTap: acceptTOS, // Tap only if at the end
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.transparent,
                )),
            child: const Center(
              child: Text(
                'I Accept the Terms of Service',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.05),
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 2.0,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25),
                  // Introduction
                  Text(
                    '1. Introduction',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome to Barzzy. These Terms of Service ("Terms") govern your access to and use of our services, including our website, mobile application, and any other software, tools, features, or functionality provided on or in connection with our services (collectively, the "Service"). Please read these Terms carefully before using the Service. By accessing or using the Service, you agree to be bound by these Terms and our Privacy Policy, which is incorporated by reference into these Terms.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Eligibility
                  Text(
                    '2. Eligibility',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'You must be at least 21 years old to use the Service. By using the Service, you represent and warrant that you are of legal drinking age in your jurisdiction and that you have the right, authority, and capacity to enter into these Terms. If you are under the legal drinking age in your jurisdiction or do not agree to these Terms, you must not use the Service.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Services Provided
                  Text(
                    '3. Services Provided',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Barzzy is a platform that facilitates the ordering of beverages, including alcoholic beverages, at participating establishments such as bars, pubs, and nightclubs (the "Establishments"). Barzzy does not own, operate, or control the Establishments, and is not responsible for the actions or inactions of any Establishment, including the quality, safety, legality, or availability of the items listed on the Service.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Orders and Payments
                  Text(
                    '4. Orders and Payments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'All orders placed through the Service are subject to acceptance by the relevant Establishment. Barzzy does not guarantee the availability of any item on the menu at any Establishment. Prices for items may change without notice. Barzzy is not responsible for the accuracy of pricing or any other information provided by the Establishments. All payments for orders placed through the Service are processed by the Establishments, and Barzzy does not handle or manage any payment transactions.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // User Conduct
                  Text(
                    '5. User Conduct',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'You agree to use the Service only for lawful purposes and in accordance with these Terms. You agree not to use the Service to engage in any conduct that is illegal, harmful, or otherwise objectionable, including but not limited to: \n\n- Misrepresenting your age or identity.\n- Ordering alcohol for consumption by individuals under the legal drinking age in your jurisdiction.\n- Attempting to defraud or deceive Barzzy or any Establishment.\n- Engaging in any activity that could harm the reputation of Barzzy or any Establishment.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Limitation of Liability
                  Text(
                    '6. Limitation of Liability',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'To the maximum extent permitted by applicable law, Barzzy and its affiliates, officers, directors, employees, agents, and licensors will not be liable for any direct, indirect, incidental, special, consequential, or punitive damages, including but not limited to, loss of profits, data, use, goodwill, or other intangible losses, resulting from: (i) your use or inability to use the Service; (ii) any conduct or content of any third party on the Service, including any Establishment; (iii) any content obtained from the Service; and (iv) unauthorized access, use, or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence), or any other legal theory, whether or not Barzzy has been informed of the possibility of such damage.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Indemnification
                  Text(
                    '7. Indemnification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'You agree to indemnify, defend, and hold harmless Barzzy and its affiliates, officers, directors, employees, agents, and licensors from and against any and all claims, liabilities, damages, losses, and expenses, including reasonable attorneys\' fees and costs, arising out of or in any way connected with: (i) your access to or use of the Service; (ii) your violation of these Terms; (iii) your violation of any third-party right, including without limitation any intellectual property right, publicity, confidentiality, property, or privacy right; or (iv) any claim that your use of the Service caused damage to a third party.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Governing Law
                  Text(
                    '8. Governing Law',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'These Terms and any action related thereto will be governed by and construed in accordance with the laws of the jurisdiction in which Barzzy is based, without regard to its conflict of laws principles. Any legal action or proceeding arising under these Terms will be brought exclusively in the courts located in that jurisdiction, and you hereby consent to the jurisdiction and venue of such courts.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '9. Automatic Gratuity and Pricing Acknowledgment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'By using the Barzzy platform, you acknowledge and consent that all in-app payments are subject to an automatic gratuity of 20% added to every order. The prices displayed within the application have been adjusted to reflect this gratuity, ensuring full transparency of the final charge before checkout. This automatic service charge is non-negotiable and applies to all purchases made through the platform.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  // Acceptance of Terms
                  Text(
                    '10. Acceptance of Terms',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'By clicking "Accept", you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree to these Terms, you must not use the Barzzy application. Your continued use of the Service constitutes your acceptance of these Terms.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
