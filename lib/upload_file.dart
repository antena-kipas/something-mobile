import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UploadSilabusPage extends StatefulWidget {
  @override
  _UploadSilabusPageState createState() => _UploadSilabusPageState();
}

class _UploadSilabusPageState extends State<UploadSilabusPage> {
  File? selectedFile;
  String message = '';

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost/sigasda_api/upload_silabus.php'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', selectedFile!.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      setState(() {
        message = respStr;
      });
    } else {
      setState(() {
        message = 'Upload gagal dengan status: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Silabus PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Pilih File PDF'),
            ),
            if (selectedFile != null)
              Text('File terpilih: ${selectedFile!.path}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadFile,
              child: Text('Upload File'),
            ),
            SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}
