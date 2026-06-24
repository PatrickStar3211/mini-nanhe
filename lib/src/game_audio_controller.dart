import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

enum BgmTrack {
  cozyNanhe1('惬意南河1', 'audio/cozy_nanhe_1.mp3'),
  cozyNanhe2('惬意南河2', 'audio/cozy_nanhe_2.mp3'),
  cozyNanhe3('惬意南河3', 'audio/cozy_nanhe_3.mp3'),
  cozyNanhe4('惬意南河4', 'audio/cozy_nanhe_4.mp3');

  const BgmTrack(this.label, this.assetPath);

  final String label;
  final String assetPath;
}

class GameAudioController {
  GameAudioController() : _enabled = true;

  GameAudioController.disabled() : _enabled = false;

  final bool _enabled;
  final Random _random = Random();
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _regularSfxPlayer;
  AudioPlayer? _hitSfxPlayer;
  BgmTrack selectedBgm = BgmTrack.cozyNanhe2;
  double musicVolume = 0.7;
  double soundEffectVolume = 0.8;
  bool _isPrepared = false;

  Future<void> prepare() async {
    if (!_enabled) return;
    try {
      final player = _bgmPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(musicVolume);
      await player.setSource(AssetSource(selectedBgm.assetPath));
      _isPrepared = true;
    } catch (_) {
      _isPrepared = false;
    }
  }

  void playFromUserGesture() {
    if (!_enabled) return;
    final player = _bgmPlayer ??= AudioPlayer();
    final playback = _isPrepared
        ? player.resume()
        : player.play(AssetSource(selectedBgm.assetPath));
    playback.catchError((_) {});
  }

  Future<void> changeBgm(BgmTrack track) async {
    selectedBgm = track;
    if (!_enabled) return;
    try {
      final player = _bgmPlayer ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(musicVolume);
      await player.play(AssetSource(track.assetPath));
      _isPrepared = true;
    } catch (_) {
      _isPrepared = false;
    }
  }

  void setMusicVolume(double value) {
    musicVolume = value;
    _bgmPlayer?.setVolume(value).catchError((_) {});
  }

  void setSoundEffectVolume(double value) {
    soundEffectVolume = value;
    _regularSfxPlayer?.setVolume(value).catchError((_) {});
    _hitSfxPlayer?.setVolume(value).catchError((_) {});
  }

  void playRegularInteraction() {
    if (!_enabled || soundEffectVolume == 0) return;
    _playSoundEffect(
      player: _regularSfxPlayer ??= AudioPlayer(),
      assetPath: 'audio/button.mp3',
    );
  }

  void playHitInteraction() {
    if (!_enabled || soundEffectVolume == 0) return;
    final hitAsset = _random.nextBool() ? 'audio/punch.mp3' : 'audio/slap.mp3';
    _playSoundEffect(
      player: _hitSfxPlayer ??= AudioPlayer(),
      assetPath: hitAsset,
    );
  }

  void _playSoundEffect({
    required AudioPlayer player,
    required String assetPath,
  }) {
    player
        .play(
          AssetSource(assetPath),
          volume: soundEffectVolume,
          mode: PlayerMode.lowLatency,
        )
        .catchError((_) {});
  }

  void dispose() {
    _bgmPlayer?.dispose();
    _regularSfxPlayer?.dispose();
    _hitSfxPlayer?.dispose();
  }
}
