import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8002';
    if (Platform.isAndroid) return 'http://192.168.137.1:8002';
    return 'http://127.0.0.1:8002';
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to check health');
  }

  static Future<Map<String, dynamic>> uploadDocument(File file) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      return json.decode(respStr);
    }
    throw Exception('Failed to upload document');
  }

  static Future<Map<String, dynamic>> askQuestion(String question) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ask'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'question': question}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to ask question');
  }

  static Future<List<dynamic>> listDocuments() async {
    final response = await http.get(Uri.parse('$baseUrl/documents'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['documents'] ?? [];
    }
    throw Exception('Failed to list documents');
  }

  static Future<void> deleteDocument(String filename) async {
    final response = await http.delete(Uri.parse('$baseUrl/documents/$filename'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete document');
    }
  }

  static String getDocumentUrl(String filename) {
    return '$baseUrl/documents/$filename';
  }

  static String getDocumentPageUrl(String filename, int page) {
    return '$baseUrl/documents/$filename/page/$page';
  }

  static Future<Map<String, dynamic>> generatePodcast(String filename) async {
    final response = await http.post(
      Uri.parse('$baseUrl/podcast/generate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'filename': filename}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to generate podcast: ${response.body}');
  }

  static Future<Uint8List> getAudioBytes(String urlPath) async {
    final response = await http.get(Uri.parse('$baseUrl$urlPath'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download audio bytes: ${response.statusCode}');
  }
}
