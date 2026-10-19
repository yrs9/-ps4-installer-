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
  String _statusMessage = "جاهز للإرسال إلى الـ PS4";

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
        _statusMessage = "تم اختيار الملف: $_selectedFileName";
      });
    } else if (result != null) {
      setState(() {
        _statusMessage = "تنبيه: يرجى اختيار ملف بصيغة .pkg فقط";
      });
    }
  }

  Future<void> _sendToPS4() async {
    final ip = _ipController.text.trim();
    final url = _urlController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _statusMessage = "خطأ: يرجى إدخال عنوان IP الخاص بالـ PS4";
      });
      return;
    }

    if (url.isEmpty) {
      setState(() {
        _statusMessage = "خطأ: يرجى إدخال رابط ملف الـ PKG المباشر";
      });
      return;
    }

    await _saveIp(ip);

    setState(() {
      _isLoading = true;
      _statusMessage = "جاري إرسال أمر التثبيت إلى الـ PS4...";
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
            _statusMessage = "تم إرسال أمر التثبيت بنجاح إلى البلايستيشن!";
          });
        } else {
          setState(() {
            _statusMessage = "فشل التثبيت: ${resData['status'] ?? 'خطأ غير معروف'}";
          });
        }
      } else {
        setState(() {
          _statusMessage = "خطأ من ال
