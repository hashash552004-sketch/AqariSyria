import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String _apiKey = '2a239b91838d335275e14115a6e2aa24';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  static Future<String> uploadImage(File image) async {
    final bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(_uploadUrl),
      body: {
        'key': _apiKey,
        'image': base64,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'] as String;
    } else {
      throw Exception('فشل رفع الصورة: ${response.statusCode}');
    }
  }
}
