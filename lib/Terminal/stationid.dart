import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Terminal/terminal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BartenderIDScreen extends StatefulWidget {
  const BartenderIDScreen({super.key});

  @override
  BartenderIDScreenState createState() => BartenderIDScreenState();
}

class BartenderIDScreenState extends State<BartenderIDScreen> {
  final ValueNotifier<String?> selectedLetter = ValueNotifier<String?>(null);

  Future<void> _handleSubmit(String bartenderID) async {
    final loginData = LoginCache();
    final negativeBarID = await loginData.getUID();
    final barId = -1 * negativeBarID;

    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => OrdersPage(
          bartenderID: bartenderID.toUpperCase(),
          barID: barId,
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
                  'B A R Z Z Y',
                  style: GoogleFonts.megrim(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
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
                '        Select Station ID',
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
                                : Colors.grey[800],
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
                        'ESC',
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
}
