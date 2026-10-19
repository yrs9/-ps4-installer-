import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 PKG Installer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  String? _selectedFileName;
  bool _isLoading = false;
  String _statusMessage = "Ready to send to PS4";

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ps4_ip') ?? '';
    });
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ps4_ip', ip);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.name.endsWith('.pkg')) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _statusMessage = "Selected file: $_selectedFileName";
      });
    } else if (result != null) {
      setState(() {
        _statusMessage = "Please select a .pkg file only";
      });
    }
  }

  Future<void> _sendToPS4() async {
    final ip = _ipController.text.trim();
    final url = _urlController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _statusMessage = "Error: Please enter PS4 IP address";
      });
      return;
    }

    if (url.isEmpty) {
      setState(() {
        _statusMessage = "Error: Please enter direct PKG URL";
      });
      return;
    }

    await _saveIp(ip);

    setState(() {
      _isLoading = true;
      _statusMessage = "Sending installation command to PS4...";
    });

    try {
      final endpoint = Uri.parse('http://$ip:12800/api/install');
      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'direct',
          'packages': [url],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          setState(() {
            _statusMessage = "Installation command sent successfully!";
          });
        } else {
          setState(() {
            _statusMessage = "Failed: ${resData['status'] ?? 'Unknown error'}";
          });
        }
      } else {
        setState(() {
          _statusMessage = "PS4 Error (Code: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Connection failed. Check GoldHEN and IP";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS4 PKG Installer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.sports_esports,
              size: 80,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PS4 IP Address',
                hintText: 'e.g., 192.168.1.50',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Direct PKG URL',
                hintText: 'http://example.com/game.pkg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFileName ?? 'Select Local PKG (Optional)'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendToPS4,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Install on PS4',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
