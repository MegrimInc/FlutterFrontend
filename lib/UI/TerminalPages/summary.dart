import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:megrim/DTO/employeeshiftsummary.dart';
import 'package:megrim/config.dart';

class SummaryPage extends StatefulWidget {
  final int merchantId;
  final int employeeId;

  const SummaryPage(
      {super.key, required this.merchantId, required this.employeeId});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<EmployeeShiftSummary> _summaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    final url = Uri.parse(
        '${AppConfig.postgresHttpBaseUrl}/employee/${widget.merchantId}/employee-shift-summaries');

    try {
      final response =
          await HttpClient().getUrl(url).then((req) => req.close());
      final jsonString = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(jsonString) as List<dynamic>;
       final summaries = data
          .map((e) => EmployeeShiftSummary.fromJson(e as Map<String, dynamic>))
          .where((s) =>
              s.revenue != 0 || s.gratuity != 0 || s.points != 0)
          .toList();

        setState(() {
          _summaries = summaries;
          _loading = false;
        });
      } else {
        debugPrint("Status code: ${response.statusCode}");
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error fetching summaries: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight * 0.7,
      width: screenWidth,
       decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
      child: Column(
        children: [
           // Drag Bar
          Container(
              height: 7,
              width: 50,
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              )),

          const SizedBox(height: 8),
          Container(
             height: screenHeight * 0.70 - 45,
              width: screenWidth,
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _summaries.isEmpty
                    ? const Center(
                        child: Text(
                          "No data available.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _summaries.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white24),
                        itemBuilder: (context, index) {
                          final s = _summaries[index];
                          final bool isYou = s.employeeId == widget.employeeId;
          
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: name + labels
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text("Revenue:",
                                        style: TextStyle(color: Colors.white70)),
                                    SizedBox(height: 6),
                                    Text("Gratuity",
                                        style: TextStyle(color: Colors.white70)),
                                    SizedBox(height: 6),
                                    Text("Points:",
                                        style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
          
                                // Right Column: actual values
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isYou ? "YOU" : "N/A",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isYou
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text("\$${s.revenue.toStringAsFixed(2)}",
                                        style:
                                            const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 6),
                                    Text("\$${s.gratuity.toStringAsFixed(2)}",
                                        style:
                                            const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 6),
                                    Text("${s.points} pts",
                                        style:
                                            const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
          ),
        ],
      ),
    );
  }
}
