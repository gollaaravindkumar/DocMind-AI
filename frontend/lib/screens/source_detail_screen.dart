import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';

class SourceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> source;

  const SourceDetailScreen({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Source Document', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       const Icon(Icons.insert_drive_file, color: Color(0xFF06B6D4), size: 32),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Text(
                           source['filename'] ?? 'Unknown Document',
                           style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   Chip(
                     label: Text('Page ${source['page_number']}', style: const TextStyle(color: Colors.white)),
                     backgroundColor: const Color(0xFF7C3AED).withOpacity(0.5),
                     side: const BorderSide(color: Color(0xFF7C3AED)),
                   ),
                   const SizedBox(height: 24),
                   const Divider(color: Colors.white24),
                   const SizedBox(height: 16),
                   Text('Extracted Text Content:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                   const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.black45,
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.white12),
                       ),
                       child: SelectableText(
                         source['text'] ?? 'No text available.',
                         style: GoogleFonts.inter(color: Colors.white, height: 1.6),
                       ),
                     ),
                     const SizedBox(height: 24),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         ElevatedButton.icon(
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF06B6D4),
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                           icon: const Icon(Icons.open_in_browser),
                           label: const Text('Open Entire File (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                           onPressed: () async {
                             final filename = source['filename'];
                             if (filename == null) return;
                             final url = Uri.parse(ApiService.getDocumentUrl(filename.toString()));
                             try {
                               await launchUrl(url, mode: LaunchMode.externalApplication);
                             } catch (e) {
                               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open PDF: $e')));
                             }
                           },
                         ),
                         const SizedBox(height: 12),
                         OutlinedButton.icon(
                           style: OutlinedButton.styleFrom(
                             foregroundColor: const Color(0xFF7C3AED),
                             side: const BorderSide(color: Color(0xFF7C3AED)),
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                           icon: const Icon(Icons.find_in_page),
                           label: Text('Open Reference Page ${source['page_number']} Only', style: const TextStyle(fontWeight: FontWeight.bold)),
                           onPressed: () async {
                             final filename = source['filename'];
                             final page = source['page_number'];
                             if (filename == null || page == null) return;
                             
                             final url = Uri.parse(ApiService.getDocumentPageUrl(filename.toString(), int.tryParse(page.toString()) ?? 1));
                             try {
                               await launchUrl(url, mode: LaunchMode.externalApplication);
                             } catch (e) {
                               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open PDF page: $e')));
                             }
                           },
                         ),
                       ],
                     ),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
