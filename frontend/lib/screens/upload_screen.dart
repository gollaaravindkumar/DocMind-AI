import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_button.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import '../services/app_state.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onStartQuerying;
  const UploadScreen({super.key, this.onStartQuerying});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<dynamic> documents = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final docs = await ApiService.listDocuments();
      setState(() {
        documents = docs;
      });
      int totalChunks = 0;
      for (var doc in docs) {
        totalChunks += (doc['chunks'] as num?)?.toInt() ?? 0;
      }
      AppState().setIndexingStats(docs.length, totalChunks);
    } catch (e) {
      // Ignore error for initial fetch if backend is sleeping
    }
  }

  Future<void> _deleteDocument(String filename) async {
    try {
      await ApiService.deleteDocument(filename);
      await _fetchDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() { isLoading = true; });
      File file = File(result.files.single.path!);
      try {
        await ApiService.uploadDocument(file);
        await _fetchDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: Color(0xFF7C3AED),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() { isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Knowledge Base', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: isLoading ? null : _pickAndUpload,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator(color: Color(0xFF06B6D4))
                    else
                      const Icon(Icons.cloud_upload_outlined, size: 64, color: Color(0xFF06B6D4)),
                    const SizedBox(height: 16),
                    Text(
                      isLoading ? 'Uploading & Processing...' : 'Tap to Upload PDF',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or drag and drop here',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Indexed Documents',
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: documents.isEmpty
                  ? const Center(child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withAlpha(50),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.picture_as_pdf, color: Color(0xFFB28CFF), size: 24),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFFFF4B4B)),
                                      onPressed: () => _deleteDocument(doc['filename']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  doc['filename'] ?? 'Unknown',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.sort, color: Color(0xFF40CEED), size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${doc['chunks'] ?? 0} CHUNKS',
                                      style: GoogleFonts.inter(color: const Color(0xFF40CEED), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withAlpha(20),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.greenAccent.withAlpha(50)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'INDEXED',
                                        style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            GlowingButton(
              text: 'Start Querying ->',
              onPressed: documents.isEmpty ? () {} : () {
                if (widget.onStartQuerying != null) {
                  widget.onStartQuerying!();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
