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
    
