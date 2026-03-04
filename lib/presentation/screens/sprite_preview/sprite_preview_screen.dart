import 'dart:async';
import 'package:flutter/material.dart';

class SpritePreviewScreen extends StatefulWidget {
  const SpritePreviewScreen({super.key});

  @override
  State<SpritePreviewScreen> createState() => _SpritePreviewScreenState();
}

class _SpritePreviewScreenState extends State<SpritePreviewScreen> {
  int _idleFrame = 0;
  int _walkFrame = 0;
  int _attackFrame = 0;
  Timer? _timer;

  static const _idleFrames = 4;
  static const _walkFrames = 6;
  static const _attackFrames = 6;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() {
        _idleFrame = (_idleFrame + 1) % _idleFrames;
        _walkFrame = (_walkFrame + 1) % _walkFrames;
        _attackFrame = (_attackFrame + 1) % _attackFrames;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _frameName(int frame) => 'frame_${frame.toString().padLeft(3, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Adventurer Cat Preview'),
        backgroundColor: const Color(0xFF16213E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Static rotation
            const Text(
              'Rotation (South)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/characters/adventurer_cat/rotations/south.png',
                width: 128,
                height: 128,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 32),

            // Idle animation
            const Text(
              'Idle Animation',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/characters/adventurer_cat/animations/breathing-idle/south/${_frameName(_idleFrame)}.png',
                width: 128,
                height: 128,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 32),

            // Walk animation
            const Text(
              'Walk Animation',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/characters/adventurer_cat/animations/walking/south/${_frameName(_walkFrame)}.png',
                width: 128,
                height: 128,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 32),

            // Attack animation
            const Text(
              'Attack Animation',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/characters/adventurer_cat/animations/cross-punch/south/${_frameName(_attackFrame)}.png',
                width: 128,
                height: 128,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 32),

            // All 8 directions
            const Text(
              '8 Directions',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final dir in [
                  'north',
                  'north-east',
                  'east',
                  'south-east',
                  'south',
                  'south-west',
                  'west',
                  'north-west',
                ])
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/characters/adventurer_cat/rotations/$dir.png',
                          width: 64,
                          height: 64,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dir,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
