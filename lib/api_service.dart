import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiKey = '22cca49f898942a8830d5359131fec03';

  Future<List<dynamic>> fetchNews({String query = 'teknologi'}) async {
    final url =
        'https://newsapi.org/v2/everything?q=$query&language=id&sortBy=publishedAt&apiKey=$apiKey';

    print('DEBUG URL: $url');

    final response = await http.get(Uri.parse(url));

    print('DEBUG STATUS: ${response.statusCode}');
    print('DEBUG BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['articles'] != null && data['articles'].isNotEmpty) {
        return data['articles'];
      } else {
        return []; // tidak crash, hanya tampil "Berita tidak ditemukan"
      }
    } else {
      throw Exception('Gagal memuat berita: ${response.statusCode}');
    }
  }
}
