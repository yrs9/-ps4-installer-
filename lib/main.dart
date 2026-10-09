import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

void main() {
  runApp(const PS4InstallerApp());
}

class PS4InstallerApp extends StatelessWidget {
  const PS4InstallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 Package Installer',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  String _statusMessage = 'جاهز للاستخدام';
  bool _isLoading = false;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _loadSavedIP();
  }

  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ps4_ip') ?? '192.168.0.131';
    });
  }

  Future<void> _saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ps4_ip', ip);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pkg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _statusMessage = 'تم اختيار: $_selectedFileName';
      });
    }
  }

  Future<String?> _getPhoneIP() async {
    final info = NetworkInfo();
    return await info.getWifiIP();
  }

  Future<void> _sendToPS4() async {
    if (_selectedFilePath == null) {
      setState(() => _statusMessage = 'يرجى اختيار ملف PKG أولاً!');
      return;
    }

    if (_ipController.text.trim().isEmpty) {
      setState(() => _statusMessage = 'يرجى كتابة IP الـ PS4!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري الاتصال وإرسال اللعبة...';
    });

    await _saveIP(_ipController.text.trim());

    try {
      await _server?.close(force: true);

      final file = File(_selectedFilePath!);
      final parentDir = file.parent.path;

      var handler = createStaticHandler(parentDir, defaultDocument: _selectedFileName);
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);

      final phoneIp = await _getPhoneIP() ?? '127.0.0.1';
      final pkgUrl = 'http://$phoneIp:8080/$_selectedFileName';

      final ps4Ip = _ipController.text.trim();
      final response = await http.post(
        Uri.parse('http://$ps4Ip:12800/api/install'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'direct',
          'packages': [pkgUrl]
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _statusMessage = '✅ تم إرسال اللعبة بنجاح لـ PS4!');
      } else {
        setState(() => _statusMessage = '❌ فشل التثبيت. الكود: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _statusMessage = '❌ خطأ في الاتصال: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مُثبت ألعاب PS4'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عنوان IP لـ PS4',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFileName ?? 'اختر ملف PKG من الجوال'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendToPS4,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال وتثبيت على PS4'),
            ),
            const SizedBox(height: 30),
            Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
