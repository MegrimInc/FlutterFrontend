import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/UI/AuthPages/components/toggle.dart';
import 'package:megrim/UI/TerminalPages/create.dart';
import 'package:megrim/UI/TerminalPages/inventory.dart';
import 'package:megrim/UI/TerminalPages/terminal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  SelectPageState createState() => SelectPageState();
}

class SelectPageState extends State<SelectPage> {
  @override
  void initState() {
    super.initState();
    _setUpInventory();
  }

  Future<void> _setUpInventory() async {
    final loginData = LoginCache();
    final negativeMerchantId = await loginData.getUID();
    final merchantId = -1 * negativeMerchantId;

    try {
      debugPrint("Setting up inventory...");
      // ignore: use_build_context_synchronously
      final inv = Provider.of<Inventory>(context, listen: false);
      await inv.fetchMerchantDetails(merchantId);
      debugPrint("Inventory setup completed successfully.");
    } catch (e) {
      debugPrint("Error setting up inventory: $e");
    }
  }


  void _createEmployee() async {
    final loginData = LoginCache();
    final negativeMerchantId = await loginData.getUID();
    final merchantId = -1 * negativeMerchantId;
    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEmployeePage(merchantId: merchantId),
      ),
    );
    // when CreateEmployeePage pops with `pop(true)`, you can refresh:
    setState(() {});
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
    final inv = Provider.of<Inventory>(context);
    final merchant = inv.merchant;

    if (merchant == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final employees = merchant.employees ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    iconSize: 27,
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                  const Text(
                    "Employees",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    iconSize: 33,
                    onPressed: _createEmployee,
                    tooltip: 'Add Employee',
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              color: Colors.white24, size: 80),
                          const SizedBox(height: 20),
                          const Text(
                            "No Employees Found",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text("Create First Employee",
                                style: TextStyle(fontSize: 16)),
                            onPressed: _createEmployee,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: employees.length,
                      itemBuilder: (ctx, i) {
                        final emp = employees[i];
                        final name = emp.name ?? "";

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Terminal(
                                  employeeId: emp.employeeId!,
                                  merchantId: merchant.merchantId!,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ✨ --- NEW: Outer CircleAvatar for the white border --- ✨
                              CircleAvatar(
                                radius: 101,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 100,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: emp.imageUrl != null
                                      ? NetworkImage(emp.imageUrl!)
                                      : null,
                                  child: emp.imageUrl == null
                                      ? const Icon(Icons.person,
                                          size: 35, color: Colors.white60)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // ✨ --- NEW: Email text --- ✨
                              Text(
                                emp.email ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
