import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({super.key});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  List<dynamic> documents = [];
  bool isLoading = false;
  
  String? selectedFile;
  bool isGenerating = false;
  List<dynamic>? script;
  String? audioUrl;
  Uint8List? audioBytes;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if(mounted) setState(() { isPlaying = state == PlayerState.playing; });
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if(mounted) setState(() { duration = newDuration; });
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if(mounted) setState(() { position = newPosition; });
    });
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    setState(() { isLoading = true; });
    try {
      final docs = await ApiService.listDocuments();
      if(mounted) setState(() { documents = docs; });
    } catch (e) {
      // Ignore
    } finally {
      if(mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> _generatePodcast(String filename) async {
    setState(() {
      selectedFile = filename;
      isGenerating = true;
      script = null;
      audioUrl = null;
      audioBytes = null;
      isPlaying = false;
    });
    await _audioPlayer.stop();

    try {
      final response = await ApiService.generatePodcast(filename);
      // Backend automatically securely URL Encodes the path.
      final audioPath = response['audio_url'];
      
      // Dart HTTP natively ignores strict Android Cleartext policies, so we fetch it as raw bytes!
      final fetchedBytes = await ApiService.getAudioBytes(audioPath);
      
      if(mounted) {
        setState(() {
          // If the backend magically sends script as a Map, aggressively convert it to a List!
          if (response['script'] is Map) {
            script = [response['script']];
          } else {
            script = response['script'];
          }
          audioBytes = fetchedBytes;
          isGenerating = false;
        });
        await _audioPlayer.play(BytesSource(fetchedBytes, mimeType: 'audio/mpeg'));
      }
    } catch (e) {
      if(mounted) {
        setState(() { isGenerating = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate podcast: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DocMind Podcast', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (script == null && !isGenerating) ...[
              Text(
                'Select a Document',
                style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 16),
              if (isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
              if (!isLoading && documents.isEmpty)
                const Center(child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.white54))),
              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final filename = doc['filename'] ?? 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _generatePodcast(filename),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.podcasts, color: Color(0xFF06B6D4)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(filename, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.play_circle_fill, color: Color(0xFF7C3AED)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (isGenerating) ...[
              const Spacer(),
              const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
              const SizedBox(height: 24),
              Text(
                'Generating AI Podcast Script & Audio...',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This might take a minute...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
              ),
              const Spacer(),
            ],

            if (script != null && !isGenerating) ...[
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Deep Dive: $selectedFile',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF06B6D4)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.5),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: IconButton(
                            iconSize: 64,
                            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
                            onPressed: () async {
                              if (isPlaying) {
                                await _audioPlayer.pause();
                              } else {
                                if (audioBytes != null) {
                                  if (position > Duration.zero && position < duration) {
                                    await _audioPlayer.resume();
                                  } else {
                                    await _audioPlayer.play(BytesSource(audioBytes!, mimeType: 'audio/mpeg'));
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: position.inSeconds.toDouble(),
                      min: 0.0,
                      max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                      activeColor: const Color(0xFF06B6D4),
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.white54)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Episode Transcript',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: script!.length,
                  itemBuilder: (context, index) {
                    final line = script![index];
                    final isHostA = line['speaker'] == 'HOST_A';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isHostA ? const Color(0xFF7C3AED) : const Color(0xFF06B6D4),
                            child: Text(isHostA ? 'A' : 'B', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isHostA ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFF06B6D4).withOpacity(0.3)),
                              ),
                              child: Text(
                                line['text'] ?? '',
                                style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.white.withOpacity(0.9)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF06B6D4)),
                  label: const Text('Back to Episodes', style: TextStyle(color: Color(0xFF06B6D4))),
                  onPressed: () {
                    _audioPlayer.stop();
                    setState(() {
                      script = null;
                      audioUrl = null;
                      audioBytes = null;
                      selectedFile = null;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
