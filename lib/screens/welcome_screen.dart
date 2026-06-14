import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/strava_service.dart';
import '../themes/app_theme.dart';

const consentVersion = 'v1';

/// First screen for a new participant: study info + consent + "Connect with
/// Strava". Connecting Strava IS the sign-in — no email/password. Consent +
/// demographics are saved locally and sent to the backend on connect.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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

  Future<void> _connect() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please tick the consent box to join.'),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_consent', true);
    await prefs.setString('pending_age_range', _ageRange);
    await prefs.setString('pending_training_level', _trainingLevel);
    await prefs.setInt('pending_cycle_length', _cycleLength);
    await prefs.setString('profile_name', _nameController.text.trim());
    // Full-page redirect to Strava; we return here with ?code and sign in.
    await StravaService.instance.beginAuthorization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Text('Welcome to SOMA Connect',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            Text(
              'A research study on how menstrual-cycle phase relates to running performance. Join by connecting Strava — that\'s your secure sign-in, no password needed. We collect your runs (via Strava) and the cycle dates you enter, stored under a pseudonymous ID.\n\n'
              'Your data is used only for this research, kept confidential, and you can withdraw and request deletion any time. Cycle phases are estimates from dates, not hormone measurements, and nothing here is medical advice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '[Placeholder consent text — replace with your IRB/DPIA-approved wording before launch.]',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
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
              child: FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.directions_run),
                label: const Text('Agree & connect with Strava'),
              ),
            ),
            const SizedBox(height: 20),
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
