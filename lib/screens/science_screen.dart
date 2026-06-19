import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';

/// Female athlete science feed. Reads facts from the Supabase `science_facts`
/// table (the team edits them in the Table Editor). Falls back to the built-in
/// list if the table is empty or unreachable, so it never shows blank.
class ScienceScreen extends StatefulWidget {
  const ScienceScreen({super.key});

  @override
  State<ScienceScreen> createState() => _ScienceScreenState();
}

class _ScienceScreenState extends State<ScienceScreen> {
  List<ScienceFact> _facts = SampleData.scienceFacts;

  static const _tints = [
    Color(0xFFF4F7FB),
    Color(0xFFF1F6FB),
    Color(0xFFF5F4FB),
    Color(0xFFF2F7FA),
    Color(0xFFF6F8FC),
    Color(0xFFEFF4FC),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('science_facts')
          .select()
          .eq('published', true)
          .order('sort_order', ascending: true);
      final list = rows as List;
      if (list.isEmpty) return; // keep fallback
      final facts = <ScienceFact>[];
      for (var i = 0; i < list.length; i++) {
        final r = list[i];
        facts.add(ScienceFact(
          emoji: (r['emoji'] ?? '') as String,
          tag: (r['tag'] ?? '') as String,
          body: (r['body'] ?? '') as String,
          cardColor: _tints[i % _tints.length],
        ));
      }
      if (mounted) setState(() => _facts = facts);
    } catch (e) {
      debugPrint('load science facts failed: $e'); // keep fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts = _facts;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Female athlete science',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Evidence-based insights for female runners',
                style: TextStyle(fontSize: 14, color: FemoraTheme.warmText)),
            const SizedBox(height: 20),
            ...facts.map(
              (fact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FactCard(fact: fact),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FemoraTheme.lavenderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔬  About this research',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: FemoraTheme.lavender),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All content in this section is reviewed against published research. We aim to represent findings accurately and note where evidence is preliminary or contested. Female physiology research is an evolving field.',
                    style: TextStyle(
                        fontSize: 13,
                        color: FemoraTheme.lavender,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Fact Card ──────────────────────────────────────────────────────────────
class _FactCard extends StatefulWidget {
  final ScienceFact fact;

  const _FactCard({required this.fact});

  @override
  State<_FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<_FactCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final fact = widget.fact;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: fact.cardColor,
          border: Border.all(color: FemoraTheme.warmBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fact.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              fact.body,
              style: const TextStyle(
                  fontSize: 14, color: FemoraTheme.ink, height: 1.6),
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: FemoraTheme.warmGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fact.tag,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: FemoraTheme.warmText),
                  ),
                ),
                Text(
                  _expanded ? 'Show less ↑' : 'Read more ↓',
                  style: const TextStyle(
                      fontSize: 11, color: FemoraTheme.warmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
