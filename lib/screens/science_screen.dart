import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ScienceScreen extends StatelessWidget {
  const ScienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facts = SampleData.scienceFacts;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ───────────────────────────────────────────────
            Text('Female athlete science',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Evidence-based insights for female runners',
                style:
                    TextStyle(fontSize: 14, color: FemoraTheme.warmText)),

            const SizedBox(height: 20),

            // ── Fact Cards ────────────────────────────────────────────
            ...facts.map(
              (fact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FactCard(fact: fact),
              ),
            ),

            const SizedBox(height: 8),

            // ── Research Note ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FemoraTheme.lavenderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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
  final dynamic fact; // ScienceFact

  const _FactCard({required this.fact});

  @override
  State<_FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<_FactCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
        parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

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