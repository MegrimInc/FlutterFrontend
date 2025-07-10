import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:megrim/UI/TerminalPages/select.dart';
import 'package:path/path.dart';
import 'package:megrim/config.dart';
import 'package:flutter/services.dart';

class CreateEmployeePage extends StatefulWidget {
  final int merchantId;
  const CreateEmployeePage({super.key, required this.merchantId});

  @override
  CreateEmployeePageState createState() => CreateEmployeePageState();
}

class CreateEmployeePageState extends State<CreateEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _thingNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  XFile? _pickedImage;
  bool _isLoading = false;

  String _selectedType = 'Person'; // Default selection

  final RegExp _allowedChars = RegExp(r'[a-zA-Z ]');

  String _formatInput(String input) {
    // Remove disallowed characters
    input = input.split('').where((c) => _allowedChars.hasMatch(c)).join();

    // Capitalize each word
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _handleTypeSelect(String type) {
    setState(() {
      _selectedType = type;
    });
  }

  Future<void> _pickImage(ImageSource src) async {
    final img = await ImagePicker().pickImage(source: src, maxWidth: 800);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(child: Text('Please upload an image.')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_pickedImage != null) {
      final filename = basename(_pickedImage!.path);
      final presignRes = await http.post(
        Uri.parse(
            '${AppConfig.postgresHttpBaseUrl}/employee/upload-image-url?merchantId=${widget.merchantId}&filename=$filename'),
      );

      if (presignRes.statusCode != 200) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to get upload URL')));
        return;
      }

      final presignData = json.decode(presignRes.body) as Map<String, dynamic>;
      final uploadUrl = presignData['url'] as String;
      final key = presignData['key'] as String;

      final bytes = await File(_pickedImage!.path).readAsBytes();
      final putRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );

      if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('S3 upload failed')));
        return;
      }

      imageUrl = 'https://megrimages.s3.us-east-1.amazonaws.com/$key';
    }

    // Compose the name
    String name;
    if (_selectedType == 'Person') {
      final first = _formatInput(_firstNameCtl.text);
      final last = _formatInput(_lastNameCtl.text);
      name = '$first $last'.trim();
    } else {
      name = _formatInput(_thingNameCtl.text);
    }

    // API payload
    final payload = {
      'merchantId': widget.merchantId,
      'name': name,
      'email': _emailCtl.text.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    final createRes = await http.post(
      Uri.parse('${AppConfig.postgresHttpBaseUrl}/employee/createEmployee'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (createRes.statusCode != 201) {
      setState(() => _isLoading = false);
      debugPrint('--- FAILED TO CREATE EMPLOYEE ---');
      debugPrint('Status Code: ${createRes.statusCode}');
      debugPrint('Data Sent: ${json.encode(payload)}');
      debugPrint('Response Body: ${createRes.body}');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Create employee failed')));
      return;
    }

    setState(() => _isLoading = false);
    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => SelectPage(),
      ),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Employee',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ◉ Avatar placeholder
              Center(
                child: CircleAvatar(
                  radius: 101,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : null,
                    child: _pickedImage == null
                        ? Icon(Icons.person, size: 60, color: Colors.white38)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ◉ Take / pick buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),

              Spacer(flex: 1),

              // ◉ Selector buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('Person'),
                    selectedColor: Colors.white12,
                    backgroundColor: Colors.white,
                    selected: _selectedType == 'Person',
                    onSelected: (_) => _handleTypeSelect('Person'),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text('Thing'),
                    selectedColor: Colors.white12,
                    backgroundColor: Colors.white,
                    selected: _selectedType == 'Thing',
                    onSelected: (_) => _handleTypeSelect('Thing'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ◉ Conditionally show fields
              if (_selectedType == 'Person') ...[
                TextFormField(
                  controller: _firstNameCtl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: inputDecoration.copyWith(labelText: 'First Name'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: inputDecoration.copyWith(labelText: 'Last Name'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              if (_selectedType == 'Thing') ...[
                TextFormField(
                  controller: _thingNameCtl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: inputDecoration.copyWith(labelText: 'Name'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: inputDecoration.copyWith(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@')
                    ? null
                    : 'Valid email required',
              ),
              const SizedBox(height: 30),

              // ◉ Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade600,
                  ),
                  onPressed: _isLoading ? null : () => _submit(context),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Save Employee'),
                ),
              ),

              Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _thingNameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }
}
