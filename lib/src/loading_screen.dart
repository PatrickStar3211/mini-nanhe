import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _started = false;
  bool _ready = false;
  bool _entering = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    await Future.wait(
      startupPreloadAssets.map(
        (asset) => precacheImage(AssetImage(asset), context),
      ),
    );

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  Future<void> _enterGame() async {
    if (!_ready || _entering) return;

    setState(() => _entering = true);
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111A24),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage(loadingRainyBoxAsset),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x6608111C),
                  Colors.transparent,
                  Color(0x22000000),
                  Color(0xAA07101A),
                ],
                stops: [0, 0.3, 0.68, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
              child: Column(
                children: [
                  const Text(
                    '迷你南河',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF4F7FB),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      shadows: [
                        Shadow(
                          color: Color(0xCC07101A),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: _ready
                        ? SizedBox(
                            key: const ValueKey('enter-button'),
                            width: 220,
                            child: FilledButton(
                              key: const Key('enter-game-button'),
                              onPressed: _enterGame,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE9B66F),
                                foregroundColor: const Color(0xFF352414),
                                minimumSize: const Size.fromHeight(54),
                                elevation: 5,
                                shadowColor: const Color(0xAA000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                    color: Color(0xFFFFE1AC),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: const Text(
                                '带他回家',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          )
                        : const Column(
                            key: ValueKey('loading-indicator'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFFF3D7A6),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '正在加载……',
                                style: TextStyle(
                                  color: Color(0xFFDCE5EE),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
