  // دالة اختيار ملف اللعبة مباشرة دون أذونات معقدة
  Future<void> _requestPermissionAndPickFile() async {
    try {
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
      } else {
        setState(() {
          _statusMessage = "تم إلغاء اختيار الملف.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "حدث خطأ أثناء اختيار الملف: $e";
      });
    }
  }
