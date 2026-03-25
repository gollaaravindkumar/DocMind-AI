import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../services/app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final state = AppState();
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFF8A4CFC), size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insights', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                    Text('Document Intelligence Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF40CEED), fontSize: 12)),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Row 1: Stat Cards
                Row(
                  children: [
                    Expanded(child: _buildStatCard('${state.documentsIndexed}', 'Documents Indexed', const Color(0xFFB28CFF))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('${state.totalChunks}', 'Total Chunks', const Color(0xFF40CEED))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Row 2: Query History
                _buildQueryHistory(state),
                const SizedBox(height: 24),

                // Row 3: Top Source Documents
                _buildTopSources(state),
                const SizedBox(height: 24),

                // Row 4: Chunk Retrieval Map
                _buildChunkMap(state),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatCard(String value, String title, Color color) {
    return GlassCard(
      glowColor: color,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFFABABAB), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQueryHistory(AppState state) {
    final history = state.queryHistory;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF40CEED), size: 24),
              const SizedBox(width: 8),
              Text('Query History', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          if (history.isEmpty)
            const Text('No queries yet', style: TextStyle(color: Colors.white54)),
          ...history.take(4).map((q) {
            final idx = history.indexOf(q);
            return _buildQueryItem(
              q['query'] as String,
              '${((q['relevance'] as double) * 100).toInt()}% RELEVANCE',
              isLast: idx == history.length - 1 || idx == 3,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQueryItem(String text, String badge, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.5))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge, style: GoogleFonts.inter(color: const Color(0xFF40CEED), fontSize: 9, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildTopSources(AppState state) {
    final sources = state.sourceCites.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final int maxCites = sources.isEmpty ? 1 : sources.first.value;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Color(0xFFB28CFF), size: 24),
              const SizedBox(width: 8),
              Text('Top Source Documents', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          if (sources.isEmpty)
            const Text('No sources cited yet', style: TextStyle(color: Colors.white54)),
          ...sources.take(3).map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSourceItem(s.key, '${s.value} Cites', s.value / maxCites),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSourceItem(String title, String cites, double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: const Color(0xFFABABAB), fontSize: 12, fontWeight: FontWeight.w500))),
            const SizedBox(width: 12),
            Text(cites, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF40CEED)],
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF40CEED).withValues(alpha: 0.5), blurRadius: 10)
                ]
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildChunkMap(AppState state) {
    final activeHeatmap = state.activeChunks.map((idx) => idx % 40).toSet();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view, color: Color(0xFF40CEED), size: 24),
              const SizedBox(width: 8),
              Text('Chunk Retrieval Map', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Vector space density and active retrieval clusters', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFABABAB))),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 40,
            itemBuilder: (context, index) {
              final bool isHighlight = activeHeatmap.contains(index);
              final double bgOpacity = isHighlight ? 1.0 : ((index * 7) % 50 + 10) / 100.0;
              
              if (isHighlight) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF40CEED),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF40CEED).withValues(alpha: 0.6), blurRadius: 8),
                    ]
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F).withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
