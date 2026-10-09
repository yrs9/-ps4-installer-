import 'package:flutter/material.dart';

void main() {
  runApp(const PS4InstallerApp());
}

class PS4InstallerApp extends StatelessWidget {
  const PS4InstallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 PKG Installer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const InstallerHomePage(),
    );
  }
}

class InstallerHomePage extends StatefulWidget {
  const InstallerHomePage({super.key});

  @override
  State<InstallerHomePage> createState() => _InstallerHomePageState();
}

class _InstallerHomePageState extends State<InstallerHomePage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isConnected = false;
  String _statusMessage = 'جاهز للاتصال بـ PS4';

  void _connectToPS4() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _statusMessage = 'الرجاء إدخال آي بي البلايستيشن 4 بشكل صحيح';
      });
      return;
    }
    setState(() {
      _isConnected = true;
      _statusMessage = 'تم الاتصال بنجاح مع الجهاز: $ip';
    });
  }

  void _sendPkg() {
    final url = _urlController.text.trim();
    if (!_isConnected) {
      setState(() {
        _statusMessage = 'يرجى الاتصال بـ PS4 أولاً!';
      });
      return;
    }
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'الرجاء إدخال رابط ملف الـ PKG';
      });
      return;
    }
    setState(() {
      _statusMessage = 'جاري إرسال الحزمة وتثبيتها على الـ PS4...';
    });
    
    // محاكاة عملية الإرسال الناجحة
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusMessage = 'تم إرسال اللعبة بنجاح إلى الـ PS4!';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS4 PKG Installer - خبير الألعاب'),
        backgroundColor: const Color(0xFF1F1F1F),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات الاتصال بـ PS4',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'PS4 IP Address (مثال: 192.168.1.50)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wifi),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _connectToPS4,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.link),
                      label: const Text('اتصال بالجهاز', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رابط لعبة / حزمة PKG',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'أدخل رابط ملف PKG المباشر',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.download),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _sendPkg,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text('إرسال وتثبيت على PS4', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'الحالة: $_statusMessage',
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

