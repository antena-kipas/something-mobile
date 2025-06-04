import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchSilabus() async {
  var url = Uri.parse("http://192.168.56.1/sigasda_api/get_silabus.php");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Gagal memuat data silabus');
  }
}
