// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Use a dark theme at night'),
                value: settings.isDarkMode,
                onChanged: settings.toggleDarkMode,
              ),
              const SizedBox(height: 16),
              Text(
                'Default view',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              RadioListTile<DefaultViewMode>(
                title: const Text('Board (tiles)'),
                subtitle: const Text('Open directly to your paths'),
                value: DefaultViewMode.board,
                groupValue: settings.defaultViewMode,
                onChanged: (mode) {
                  if (mode != null) {
                    settings.setDefaultViewMode(mode);
                  }
                },
              ),
              RadioListTile<DefaultViewMode>(
                title: const Text('Map'),
                subtitle: const Text('Open to your life map first'),
                value: DefaultViewMode.map,
                groupValue: settings.defaultViewMode,
                onChanged: (mode) {
                  if (mode != null) {
                    settings.setDefaultViewMode(mode);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SwitchListTile(
                title: const Text('Use location on map'),
                subtitle: const Text('Show your position and nearby pins'),
                value: settings.useLocation,
                onChanged: settings.setUseLocation,
              ),
              const SizedBox(height: 16),
              Text(
                'More settings coming soon…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
