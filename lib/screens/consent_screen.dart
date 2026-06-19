import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_theme.dart';

const _consentVersion = 'v1';

/// Informed-consent gate. Recorded against the participant's account before any
/// data is collected. Replace the placeholder text with your IRB/DPIA-approved
/// wording before launch.
class ConsentScreen extends StatefulWidget {
  final VoidCallback onConsented;
  const ConsentScreen({super.key, required this.onConsented});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _nameController = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String _ageRange = '25–34';
  String _trainingLevel = 'Recreational';
  int _cycleLength = 28;

  static const _ageRanges = ['Under 18', '18–24', '25–34', '35–44', '45+'];
  static const _levels = ['Beginner', 'Recreational', 'Competitive', 'Elite'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please tick the consent box to continue.'),
      ));
      return;
    }
    if (_ageRange == 'Under 18') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This study is for participants aged 18 or over.'),
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').upsert({
        'user_id': uid,
        'consent_version': _consentVersion,
        'consented_at': DateTime.now().toUtc().toIso8601String(),
        'age_range': _ageRange,
        'training_level': _trainingLevel,
        'cycle_length': _cycleLength,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', _nameController.text.trim());
      widget.onConsented();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save consent. $e'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Research consent',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            Text(
              'SOMA Connect is a research study exploring how menstrual-cycle phase relates to running performance. With your consent we securely collect the running data you upload (from your sports app, such as Garmin Connect) and the cycle dates you enter, stored under a pseudonymous ID.\n\n'
              'Your data is used only for this research, kept confidential, and you may withdraw and request deletion at any time. Cycle phases are estimates from dates, not hormone measurements, and nothing here is medical advice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display name (optional)',
                filled: true,
                fillColor: FemoraTheme.warmGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _dropdown('Age range', _ageRange, _ageRanges,
                (v) => setState(() => _ageRange = v)),
            const SizedBox(height: 12),
            _dropdown('Training level', _trainingLevel, _levels,
                (v) => setState(() => _trainingLevel = v)),
            const SizedBox(height: 16),

            Text('Average cycle length: $_cycleLength days',
                style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _cycleLength.toDouble(),
              min: 21,
              max: 35,
              divisions: 14,
              label: '$_cycleLength',
              onChanged: (v) => setState(() => _cycleLength = v.round()),
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'I am 18 or older and consent to taking part in this research and to the collection of my activity and cycle data.',
                      style: TextStyle(fontSize: 13, color: FemoraTheme.ink),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Agree & continue'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: FemoraTheme.warmGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}
