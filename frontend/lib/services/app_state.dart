import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Stores { 'query': String, 'relevance': double }
  final List<Map<String, dynamic>> queryHistory = [];
  
  // Stores filename -> total cites
  final Map<String, int> sourceCites = {};

  final Set<int> activeChunks = {};

  int documentsIndexed = 0;
  int totalChunks = 0;

  void addQuery(String query, double topScore) {
    queryHistory.insert(0, {
      'query': query,
      'relevance': topScore,
    });
    notifyListeners();
  }

  void addSources(List<dynamic>? sources) {
    if (sources == null) return;
    for (var src in sources) {
      final filename = src['filename']?.toString() ?? 'Unknown';
      sourceCites[filename] = (sourceCites[filename] ?? 0) + 1;
      
      final chunkId = (src['chunk_id'] as num?)?.toInt();
      if (chunkId != null && chunkId >= 0) {
        activeChunks.add(chunkId);
      }
    }
    notifyListeners();
  }

  void setIndexingStats(int docCount, int chunkCount) {
    documentsIndexed = docCount;
    totalChunks = chunkCount;
    notifyListeners();
  }
}
