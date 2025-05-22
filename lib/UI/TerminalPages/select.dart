import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/UI/AuthPages/components/toggle.dart';
import 'package:megrim/UI/TerminalPages/terminal.dart';
import 'package:megrim/config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class TerminalIdScreen extends StatefulWidget {
  const TerminalIdScreen({super.key});

  @override
  TerminalIdScreenState createState() => TerminalIdScreenState();
}

class TerminalIdScreenState extends State<TerminalIdScreen> {
  final ValueNotifier<String?> selectedLetter = ValueNotifier<String?>(null);
  Set<String> activeTerminals = {};

  @override
  void initState() {
    super.initState();
    _fetchActiveTerminals();
  }

  Future<void> _handleSubmit(String terminal) async {
    final loginData = LoginCache();
    final negativeMerchantId = await loginData.getUID();
    final merchantId = -1 * negativeMerchantId;

    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => Terminal(
          terminal: terminal.toUpperCase(),
          merchantId: merchantId,
        ),
      ),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  void _logout() {
    final loginData = LoginCache();
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setSignedIn(false);
    loginData.setUID(0);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const SizedBox(height: 150),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Megrim',
                  style: GoogleFonts.megrim(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 47,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '        Select Terminal Id',
                style: TextStyle(
                  fontSize: 17.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // 6 columns for the alphabet buttons
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 30, // 26 letters + 4 additional spaces
                itemBuilder: (context, index) {
                  if (index < 26) {
                    final letter = String.fromCharCode(65 + index); // A to Z
                    return ValueListenableBuilder<String?>(
                      valueListenable: selectedLetter,
                      builder: (context, selected, child) {
                        return ElevatedButton(
                          onPressed: () {
                            selectedLetter.value = letter;
                            _handleSubmit(
                                letter); // Automatically submit on selection
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: selected == letter
                                ? Colors.black
                                : Colors.white,
                            backgroundColor: selected == letter
                                ? Colors.white
                                : activeTerminals.contains(letter)
                                    ? Colors.red[800] // Active terminal's button is green
                                    : Colors.grey[
                                        800], // Inactive terminal's button is grey
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 10),
                          ),
                          child: Text(
                            letter,
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (index == 29) {
                    // The 4th extra space (index 29)
                    return ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox
                        .shrink(); // Empty space for the other 3 positions
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchActiveTerminals() async {
    final loginData = LoginCache();
    final negativeMerchantId = await loginData.getUID();
    final merchantId = -1 * negativeMerchantId;


    try {
      final url = Uri.parse(
          "${AppConfig.redisHttpBaseUrl}/checkTerminals?merchantId=$merchantId");

          // final url = Uri.parse(
          // "${AppConfig.postgresApiBaseUrl}/ws/http/checkTerminals?merchantId=$merchantId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          activeTerminals =
              response.body.split('').toSet(); // Parse the response string
        });
      } else {
        debugPrint(
            "Failed to fetch active terminals. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching active terminals: $e");
    }
  }
}