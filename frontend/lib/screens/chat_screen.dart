import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import 'source_detail_screen.dart';
import '../services/app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<dynamic>? sources;

  ChatMessage({required this.text, required this.isUser, this.sources});
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await ApiService.askQuestion(text);
      if (mounted) {
        setState(() {
          final List<dynamic>? sources = response['sources'];
          double maxScore = 0.0;
          if (sources != null && sources.isNotEmpty) {
            AppState().addSources(sources);
            for (var src in sources) {
              double curScore = (src['score'] as num?)?.toDouble() ?? 0.0;
              if (curScore > maxScore) maxScore = curScore;
            }
          }
          if (maxScore > 0) {
            AppState().addQuery(text, maxScore);
          } else {
            AppState().addQuery(text, 0.95); // Fallback mock score
          }

          _messages.add(ChatMessage(
            text: response['answer'] ?? '',
            isUser: false,
            sources: response['sources'],
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: 'Error connecting to RAG backend: $e', isUser: false));
        });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DocMind AI', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: msg.isUser
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(0)),
                ),
                child: Text(msg.text, style: GoogleFonts.inter(color: Colors.white)),
              )
            : GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.text, style: GoogleFonts.inter(color: Colors.white, height: 1.5)),
                    if (msg.sources != null && msg.sources!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Text('Sources:', style: GoogleFonts.inter(color: const Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: msg.sources!.map((src) => ActionChip(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          side: const BorderSide(color: Color(0xFF06B6D4), width: 1),
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                          label: Text('${src["filename"]} (pg. ${src["page_number"]})'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SourceDetailScreen(source: src)),
                            );
                          },
                        )).toList(),
                      ),
                    ]
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              opacity: 0.1,
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask your documents...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)]),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
