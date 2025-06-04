import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;

class SilabusPage extends StatefulWidget {
  const SilabusPage({super.key});

  @override
  State<SilabusPage> createState() => _SilabusPageState();
}

class _SilabusPageState extends State<SilabusPage> {
  List<dynamic> silabusList = [];

  final String baseApiUrl = "http://192.168.56.1/sigasda_api/";
  final String baseUploadUrl = "http://192.168.56.1/sigasda_api/uploads/";

  @override
  void initState() {
    super.initState();
    fetchSilabus();
  }

  Future<void> fetchSilabus() async {
    try {
      final response =
          await http.get(Uri.parse("${baseApiUrl}get_silabus.php"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          setState(() {
            silabusList = body['data'];
          });
        } else {
          showMessage(body['message'] ?? "Tidak ada data silabus.");
        }
      } else {
        showMessage("Gagal mengambil data dari server.");
      }
    } catch (e) {
      showMessage("Terjadi kesalahan: $e");
    }
  }

  Future<void> uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseApiUrl}upload_file.php"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));
      request.fields['name'] = fileName;

      try {
        var res = await request.send();
        if (res.statusCode == 200) {
          showMessage("Upload berhasil");
          fetchSilabus();
        } else {
          showMessage("Upload gagal dengan kode: ${res.statusCode}");
        }
      } catch (e) {
        showMessage("Terjadi kesalahan saat upload: $e");
      }
    }
  }

  Future<void> deleteSilabus(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus file ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response =
            await http.get(Uri.parse("${baseApiUrl}delete_silabus.php?id=$id"));
        if (response.statusCode == 200) {
          showMessage("File berhasil dihapus");
          fetchSilabus();
        } else {
          showMessage("Gagal menghapus file");
        }
      } catch (e) {
        showMessage("Terjadi kesalahan saat menghapus file: $e");
      }
    }
  }

  Future<void> downloadFile(String pathFile) async {
    final url = "$baseUploadUrl$pathFile";

    if (kIsWeb) {
      // Web download via anchor element
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", pathFile)
        ..click();
      showMessage("Mengunduh file via browser...");
    } else {
      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          var status = await Permission.storage.request();
          if (status.isGranted) {
            Directory? dir = await getExternalStorageDirectory();
            String filename = pathFile.split('/').last;
            File file = File("${dir!.path}/$filename");

            await file.writeAsBytes(response.bodyBytes);
            showMessage("File berhasil disimpan di ${file.path}");
            OpenFile.open(file.path);
          } else {
            showMessage("Izin penyimpanan ditolak");
          }
        } else {
          showMessage("Gagal mengunduh file");
        }
      } catch (e) {
        showMessage("Terjadi kesalahan saat unduh: $e");
      }
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Silabus"),
        backgroundColor: const Color.fromARGB(255, 229, 64, 78),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: uploadFile,
          ),
        ],
      ),
      body: silabusList.isEmpty
          ? const Center(child: Text("Belum ada file silabus"))
          : ListView.builder(
              itemCount: silabusList.length,
              itemBuilder: (context, index) {
                final item = silabusList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.purple.shade50,
                  child: ListTile(
                    title: Text(item['nama_file'] ?? '-'),
                    subtitle: Text(item['path_file'] ?? '-'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () =>
                              downloadFile(item['path_file'] ?? ""),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteSilabus(int.parse(item['id'])),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
