import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PS4InstallerApp());
}

class PS4InstallerApp extends StatelessWidget {
  const PS4InstallerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 PKG Installer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const InstallerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InstallerHomePage extends StatefulWidget {
  const InstallerHomePage({Key? key}) : super(key: key);

  @override
  State<InstallerHomePage> createState() => _InstallerHomePageState();
}

class _InstallerHomePageState extends State<InstallerHomePage> {
  final TextEditingController _ipController = TextEditingController();
  String? _selectedFilePath;
  String _statusMessage = 'جاهز للاتصال وتركيب الألعاب';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  // استرجاع أيباتي المحفوظة مسبقاً عبر SharedPreferences
  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ps4_ip') ?? '';
    });
  }

  // حفظ الأيبات
  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ps4_ip', ip);
  }

  // اختيار ملف الـ PKG من الهاتف
  Future<void> _pickPkgFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pkg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _statusMessage = 'تم اختيار الملف: ${result.files.single.name}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في اختيار الملف: $e';
      });
    }
  }

  // إرسال طلب التثبيت إلى GoldHEN API (البورت 12800)
  Future<void> _sendToPS4() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _statusMessage = 'الرجاء إدخال عنوان IP الخاص بجهاز PS4';
      });
      return;
    }

    if (_selectedFilePath == null) {
      setState(() {
        _statusMessage = 'الرجاء اختيار ملف PKG أولاً';
      });
      return;
    }

    await _saveIp(ip);
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري الإرسال إلى PS4...';
    });

    try {
      // بناء رابط الـ API الخاص بـ GoldHEN (المنفذ 12800)
      final url = Uri.parse('http://$ip:12800/api/install');
      
      // ملاحظة: يتم إرسال مسار الرابط أو بيانات الـ PKG حسب بروتوكول الـ Remote Package Installer
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'direct',
          'packages': [_selectedFilePath]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'تم إرسال اللعبة بنجاح إلى جهاز PS4! تحقق من شاشة البلايستيشن.';
        });
      } else {
        setState(() {
          _statusMessage = 'فشل الاتصال: رمز الاستجابة ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء الاتصال بالـ PS4: $e';
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
        title: const Text('PS4 PKG Installer (Flutter)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'PS4 IP Address',
                hintText: 'مثال: 192.168.1.15',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickPkgFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('اختيار ملف PKG'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12)),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilePath != null
                  ? 'الملف المختار: ${_selectedFilePath!.split('/').last}'
                  : 'لم يتم اختيار أي ملف PKG بعد',
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendToPS4,
                    icon: const Icon(Icons.send),
                    label: const Text('تثبيت على PS4'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.amberAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
