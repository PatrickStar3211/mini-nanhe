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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      top: constraints.maxHeight * 0.1,
                      left: 20,
                      right: 20,
                      child: const _GameTitle(),
                    ),
                    Positioned(
                      top: constraints.maxHeight * 0.83,
                      left: 24,
                      right: 24,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: _ready
                            ? Center(
                                key: const ValueKey('enter-button'),
                                child: TextButton(
                                  key: const Key('enter-game-button'),
                                  onPressed: _enterGame,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    overlayColor: Colors.white24,
                                  ),
                                  child: const Text(
                                    '带他回家',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
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
                                      color: Color(0xFFF3F7FB),
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
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  static const _title = '迷你南河';
  static const _outlineStyle = TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.w900,
    letterSpacing: 7,
    color: Color(0xFF15283A),
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornamentLine(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFFDCEBFA),
              ),
            ),
            _ornamentLine(),
          ],
        ),
        const SizedBox(height: 9),
        Transform(
          transform: Matrix4.skewX(-0.06),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const [
                Offset(-2, 0),
                Offset(2, 0),
                Offset(0, -2),
                Offset(0, 2),
                Offset(-1.5, -1.5),
                Offset(1.5, -1.5),
                Offset(-1.5, 1.5),
                Offset(1.5, 1.5),
              ])
                Transform.translate(
                  offset: offset,
                  child: const Text(_title, style: _outlineStyle),
                ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFD7E8F5),
                    Color(0xFF9CB9D0),
                  ],
                ).createShader(bounds),
                child: const Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 7,
                    height: 1,
                    shadows: [
                      Shadow(color: Color(0xFF75B5DF), blurRadius: 18),
                      Shadow(
                        color: Color(0xCC000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornamentLine(),
            const SizedBox(width: 8),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFDCEBFA),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 5, height: 5),
            ),
            const SizedBox(width: 8),
            _ornamentLine(),
          ],
        ),
      ],
    );
  }

  Widget _ornamentLine() {
    return Container(
      width: 54,
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0xFFDCEBFA)],
        ),
      ),
    );
  }
}
