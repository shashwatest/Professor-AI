import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/embeddings/embeddings_factory.dart';
import '../services/embeddings/embeddings_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/noise_cancellation_warning_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<AIProvider, TextEditingController> _apiKeyControllers = {};

  AIProvider _defaultProvider = AIProvider.gemini;
  EmbeddingProvider _embeddingProvider = EmbeddingProvider.google;
  String _educationLevel = 'Undergraduate';
  bool _singleSpeakerMode = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (final provider in AIProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
    }
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _defaultProvider = await SettingsService.getDefaultProvider();
      _embeddingProvider = await SettingsService.getEmbeddingProvider();
      _educationLevel = await SettingsService.getEducationLevel();
      _singleSpeakerMode = await SettingsService.getSingleSpeakerMode();
      
      for (final provider in AIProvider.values) {
        final key = await SettingsService.getAPIKey(provider);
        if (key != null) {
          _apiKeyControllers[provider]!.text = key;
        }
      }
      
      // Google Project ID no longer needed for Generative AI embeddings
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await SettingsService.setDefaultProvider(_defaultProvider);
      await SettingsService.setEmbeddingProvider(_embeddingProvider);
      await SettingsService.setEducationLevel(_educationLevel);
      await SettingsService.setSingleSpeakerMode(_singleSpeakerMode);
      
      for (final provider in AIProvider.values) {
        final key = _apiKeyControllers[provider]!.text.trim();
        if (key.isNotEmpty) {
          await SettingsService.saveAPIKey(provider, key);
        } else {
          await SettingsService.deleteAPIKey(provider);
        }
      }
      
      // Google Project ID no longer needed for Generative AI embeddings
      
      // Clear embeddings cache and refresh DocumentService provider when settings change
      EmbeddingsService.clearCache();
      await EmbeddingsService.refreshDocumentServiceProvider();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSettingsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAPIKeysSection(),
          const SizedBox(height: 20),
          _buildPreferencesSection(),
        ],
      ),
    );
  }

  Widget _buildAPIKeysSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'API Keys',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...AIProvider.values.map((provider) => _buildAPIKeyField(provider)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAPIKeyField(AIProvider provider) {
    String hint;
    switch (provider) {
      case AIProvider.gemini:
        hint = 'AIza...';
        break;
      case AIProvider.openai:
        hint = 'sk-...';
        break;
      case AIProvider.meta:
        hint = 'meta_api_key...';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.name.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyControllers[provider],
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              suffixIcon: _apiKeyControllers[provider]!.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _apiKeyControllers[provider]!.clear();
                        });
                      },
                    )
                  : null,
            ),
            obscureText: true,
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDefaultProviderDropdown(),
          const SizedBox(height: 16),
          _buildEmbeddingProviderDropdown(),
          const SizedBox(height: 16),
          _buildEducationLevelDropdown(),
          const SizedBox(height: 16),
          _buildSpeakerModeSwitch(),
          const SizedBox(height: 16),
          _buildNoiseCancellationWarningReset(),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDefaultProviderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default AI Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AIProvider>(
          value: _defaultProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: AIProvider.values
              .map((provider) => DropdownMenuItem(
                    value: provider,
                    child: Text(provider.name.toUpperCase()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _defaultProvider = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmbeddingProviderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Embedding Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provider for document embeddings and similarity search. Google uses the same API key as Gemini.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<EmbeddingProvider>(
          value: _embeddingProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: EmbeddingProvider.values
              .map((provider) => DropdownMenuItem(
                    value: provider,
                    child: Text(provider.name.toUpperCase()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _embeddingProvider = value!;
            });
          },
        ),
      ],
    );
  }



  Widget _buildEducationLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Education Level',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _educationLevel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: ['High School', 'Undergraduate', 'Graduate', 'Professional']
              .map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _educationLevel = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSpeakerModeSwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Single Speaker Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Optimize transcription for single speaker',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _singleSpeakerMode,
          onChanged: (value) {
            setState(() {
              _singleSpeakerMode = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNoiseCancellationWarningReset() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Setup Warning',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reset noise cancellation warning dialog',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            await NoiseCancellationWarningDialog.resetWarningPreference();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Warning will show again on next transcription'),
                ),
              );
            }
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}