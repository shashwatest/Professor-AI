import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoiseCancellationWarningDialog extends StatefulWidget {
  const NoiseCancellationWarningDialog({super.key});

  static const String _prefKey = 'noise_cancellation_warning_dismissed';

  /// Shows the dialog if user hasn't dismissed it before
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_prefKey) ?? false;
    
    if (!dismissed && context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const NoiseCancellationWarningDialog(),
      );
    }
  }

  /// Resets the warning preference (for settings)
  static Future<void> resetWarningPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  @override
  State<NoiseCancellationWarningDialog> createState() => _NoiseCancellationWarningDialogState();
}

class _NoiseCancellationWarningDialogState extends State<NoiseCancellationWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        Icons.mic_off_outlined,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Audio Setup Recommendation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'For optimal transcription quality, we recommend disabling noise cancellation on your device.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'How to disable noise cancellation:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInstructionItem('• iPhone: Settings > Accessibility > Audio/Visual > Phone Noise Cancellation (OFF)'),
          _buildInstructionItem('• Android: Settings > Sounds > Advanced > Noise Cancellation (OFF)'),
          _buildInstructionItem('• AirPods: Settings > Bluetooth > AirPods > Noise Cancellation (OFF)'),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _dontShowAgain,
            onChanged: (value) {
              setState(() {
                _dontShowAgain = value ?? false;
              });
            },
            title: Text(
              "Don't show this again",
              style: theme.textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _dismissDialog(false),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => _dismissDialog(true),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _dismissDialog(bool acknowledged) async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(NoiseCancellationWarningDialog._prefKey, true);
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}