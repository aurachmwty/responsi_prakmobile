import 'dart:convert';
import 'package:http/http.dart' as http;

class AmiiboService {
  static const String _baseUrl = "https://www.amiiboapi.com/api/amiibo/";

  static Future<List<dynamic>> fetchAmiibos() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['amiibo'];
    } else {
      throw Exception("Failed to load amiibos");
    }
  }
}
