import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PS4 Package Sender',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SenderHomePage(),
    );
  }
}

class SenderHomePage extends StatefulWidget {
  const SenderHomePage({super.key});

  @override
  State<SenderHomePage> createState() => _SenderHomePageState();
}

class _SenderHomePageState extends State<SenderHomePage> {
  String? _selectedFilePath;
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.100");
  
  bool _isLoading = false;
  String _statusMessage = "";

  // دالة لطلب الإذن من المستخدم ثم فتح مستعرض الملفات
  Future<void> _requestPermissionAndPickFile() async {
    var status = await Permission.storage.request();
    
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (await Permission.storage.isGranted || await Permission.manageExternalStorage.isGranted || status.isGranted) {
      _pickFile();
    } else {
      setState(() {
        _statusMessage = "تم رفض إذن الوصول إلى الملفات! يرجى منحه من إعدادات الهاتف.";
      });
    }
  }

  // دالة اختيار ملف اللعبة
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pkg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _pathController.text = _selectedFilePath!;
        _statusMessage = "تم اختيار الملف بنجاح.";
      });
    }
  }

  // دالة إرسال اللعبة إلى الـ PS4 API
  Future<void> _sendToPS4() async {
    String ps4Ip = _ipController.text.trim();
    String pkgUrl = _pathController.text.trim();

    if (ps4Ip.isEmpty || pkgUrl.isEmpty) {
      setState(() {
        _statusMessage = "الرجاء التأكد من إدخال IP الـ PS4 ومسار اللعبة!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "جاري الاتصال بجهاز PS4...";
    });

    try {
      final url = Uri.parse('http://$ps4Ip:12800/api/install');
      final payload = {
        "type": "direct",
        "packages": [pkgUrl]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "تم إرسال اللعبة بنجاح إلى PS4! تحقق من ظهورها على جهازك.";
        });
      } else {
        setState(() {
          _statusMessage = "فشل الإرسال: استجابة غير صالحة من الـ PS4 (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "خطأ في الاتصال: تأكد من صحة الـ IP واتصال الشبكة ($e)";
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
        title: const Text('مرسل ألعاب PS4'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('عنوان آي بي جهاز PS4:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '192.168.1.100',
                ),
              ),
              const SizedBox(height: 20),

              // زر طلب الإذن واختيار الملف
              ElevatedButton.icon(
                onPressed: _requestPermissionAndPickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('اختر ملف اللعبة من الجهاز'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 15),
              
              const Text('مسار ملف الـ PKG المحدد:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: _pathController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'سيظهر مسار الملف هنا تلقائياً',
                ),
              ),
              const SizedBox(height: 30),

              // زر الإرسال للـ PS4
              ElevatedButton(
                onPressed: _isLoading ? null : _sendToPS4,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إرسال إلى PS4', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),

              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
