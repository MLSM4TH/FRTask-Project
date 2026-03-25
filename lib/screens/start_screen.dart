import 'dart:async';

import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _animateClouds = false;
  bool _fadeCenter = false;

  void _onStartPressed() {
    setState(() {
      _animateClouds = true;
      _fadeCenter = true;
    });

    // Wait for the cloud animation then navigate to home
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFDF2FF),
              Color(0xFFE5F3FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Clouds layer
            _buildClouds(),

            // Center content
            Center(
              child: AnimatedOpacity(
                opacity: _fadeCenter ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: _fadeCenter ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pathboard',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4C1D95),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Turn one big deadline into a calm little journey.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          backgroundColor: const Color(0xFF7C3AED),
                        ),
                        onPressed: _onStartPressed,
                        child: const Text(
                          'Start your path',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClouds() {
    // Just using rounded white containers as fake clouds
    return Stack(
      children: [
        // top-left cloud
        AnimatedPositioned(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          top: _animateClouds ? -200 : 60,
          left: _animateClouds ? -250 : 40,
          child: _cloud(width: 160, height: 80, opacity: 0.9),
        ),
        // top-right cloud
        AnimatedPositioned(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          top: _animateClouds ? -220 : 110,
          right: _animateClouds ? -260 : 30,
          child: _cloud(width: 190, height: 90, opacity: 0.95),
        ),
        // bottom-left cloud
        AnimatedPositioned(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          bottom: _animateClouds ? -220 : 90,
          left: _animateClouds ? -260 : 60,
          child: _cloud(width: 200, height: 90, opacity: 0.92),
        ),
        // bottom-right cloud
        AnimatedPositioned(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          bottom: _animateClouds ? -240 : 140,
          right: _animateClouds ? -260 : 80,
          child: _cloud(width: 170, height: 80, opacity: 0.9),
        ),
      ],
    );
  }

  Widget _cloud({
    required double width,
    required double height,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 40,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}
