import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
      title: 'PS4 PKG Installer',
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

  Future<void> _pickFileDirectly() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _statusMessage = "تم اختيار الملف: $_selectedFileName";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "حدث خطأ أثناء اختيار الملف: $e";
      });
    }
  }

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

      var uri = Uri.parse("http://$ps4Ip:12800/api/install");
      var request = http.MultipartRequest('POST', uri);
      
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
          _statusMessage = "تم إرسال اللعبة بنجاح إلى البلايستيشن!";
        });
      } else {
        setState(() {
          _statusMessage = "خطأ في الاستجابة من البلايستيشن (${response.statusCode})";
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PS4 PKG Installer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.sports_esports,
                size: 80,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'PS4 IP Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickFileDirectly,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedFileName ?? "من الهاتف اختر ملف"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _sendPkgToPS4,
                icon: const Icon(Icons.send),
                label: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تثبيت على البلايستيشن"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 30),
              Text(
