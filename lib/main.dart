import 'package:flutter/material.json'; // أو مكتباتك المستخدمة
import 'package:file_picker/file_picker.dart';
import 'package:http/http.json' as http;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PS4 Local PKG Installer',
      theme: ThemeData.dark(),
      home: const InstallerScreen(),
    );
  }
}

class InstallerScreen extends StatefulWidget {
  const InstallerScreen({Key? key}) : super(key: key);

  @override
  _InstallerScreenState createState() => _InstallerScreenState();
}

class _InstallerScreenState extends State<InstallerScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.0.131");
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;
  String _statusMessage = "";

  // دالة اختيار الملف المحلي من الهاتف
  Future<void> _pickLocalFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pkg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _statusMessage = "تم اختيار الملف: $_selectedFileName";
      });
    }
  }

  // دالة إرسال الملف محلياً للبلايستيشن عبر بايلود ريموت باكدج إستالر
  Future<void> _sendPkgToPS4() async {
    if (_selectedFilePath == null) {
      setState(() {
        _statusMessage = "الرجاء اختيار ملف PKG أولاً!";
      });
      return;
    }

    String ps4Ip = _ipController.text.trim();
    if (ps4Ip.isEmpty) {
      setState(() {
        _statusMessage = "الرجاء إدخال آي بي البلايستيشن!";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = "جاري الاتصال بالبلايستيشن وبث الملف...";
    });

    try {
      File file = File(_selectedFilePath!);
      int fileSize = await file.length();

      // الاتصال ببورت التثبيت على البلايستيشن (عادة 12800)
      var uri = Uri.parse("http://$ps4Ip:12800/api/install");
      var request = http.MultipartRequest('POST', uri);
      
      // إرسال الملف كـ Stream لكي لا يستهلك ذاكرة الهاتف العشوائية
      request.files.add(
        await http.MultipartFile.fromPath(
          'package',
          file.path,
          filename: _selectedFileName,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "تم إرسال اللعبة بنجاح إلى البلايستيشن! تابع التثبيت على الشاشة.";
        });
      } else {
        setState(() {
          _statusMessage = "خطأ في الاستجابة من البلايستيشن (Code: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "فشل الاتصال: تأكد من تشغيل GoldHEN وبورت 12800";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS4 Local PKG Installer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // حقل إدخال الآي بي الخاص بالـ PS4
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'PS4 IP Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 20),

            // زر اختيار ملف الـ PKG محلياً
            ElevatedButton.icon(
              onPressed: _pickLocalFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFileName ?? "اختر ملف PKG من الهاتف"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),

            // زر التثبيت والإرسال الرئيسي
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _sendPkgToPS4,
              icon: const Icon(Icons.send),
              label: _isUploading
                  .const ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("تثبيت على البلايستيشن (Install on PS4)"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),

            // شاشة عرض الحالة أو الأخطاء
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
