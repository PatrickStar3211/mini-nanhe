import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'character_reaction.dart';

const _buttonEffectAsset = 'audio/button.mp3';
const _pageTurnEffectAsset = 'audio/turn_page.mp3';
const _punchEffectAsset = 'audio/punch.mp3';
const _slapEffectAsset = 'audio/slap.mp3';

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
  static final _bgmAudioContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );
  static final _effectAudioContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );
  static final _voiceAudioContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _voicePlayer;
  AudioPool? _regularSfxPool;
  AudioPool? _pageTurnSfxPool;
  AudioPool? _punchSfxPool;
  AudioPool? _slapSfxPool;
  int _voiceRequestId = 0;
  BgmTrack selectedBgm = BgmTrack.cozyNanhe2;
  double musicVolume = 0.7;
  double soundEffectVolume = 0.8;
  double voiceVolume = 0.9;
  bool _isPrepared = false;

  Future<void> prepare() async {
    if (!_enabled) return;
    try {
      final player = _bgmPlayer ??= AudioPlayer();
      await player.setAudioContext(_bgmAudioContext);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(musicVolume);
      await player.setSource(AssetSource(selectedBgm.assetPath));
      final voicePlayer = _voicePlayer ??= AudioPlayer();
      await voicePlayer.setAudioContext(_voiceAudioContext);
      await voicePlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await voicePlayer.setReleaseMode(ReleaseMode.stop);
      _regularSfxPool ??= await _createEffectPool(_buttonEffectAsset, 3);
      _pageTurnSfxPool ??= await _createEffectPool(_pageTurnEffectAsset, 2);
      _punchSfxPool ??= await _createEffectPool(_punchEffectAsset, 2);
      _slapSfxPool ??= await _createEffectPool(_slapEffectAsset, 2);
      await AudioCache.instance.loadAll(
        NanheVoice.values.map((voice) => voice.assetPath).toList(),
      );
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
      await player.setAudioContext(_bgmAudioContext);
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
  }

  void setVoiceVolume(double value) {
    voiceVolume = value;
    _voicePlayer?.setVolume(value).catchError((_) {});
  }

  Future<void> playVoice(
    NanheVoice voice, {
    Duration delay = const Duration(milliseconds: 90),
  }) async {
    if (!_enabled || voiceVolume == 0) return;

    final requestId = ++_voiceRequestId;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (requestId != _voiceRequestId || !_enabled || voiceVolume == 0) return;

    try {
      final player = _voicePlayer ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(voice.assetPath), volume: voiceVolume);
      _ensureBgmContinues();
    } catch (_) {}
  }

  void playRegularInteraction() {
    if (!_enabled || soundEffectVolume == 0) return;
    _playPooledSound(_regularSfxPool, fallbackAsset: _buttonEffectAsset);
  }

  void playPageTurn() {
    if (!_enabled || soundEffectVolume == 0) return;
    _playPooledSound(_pageTurnSfxPool, fallbackAsset: _pageTurnEffectAsset);
  }

  void playHitInteraction() {
    if (!_enabled || soundEffectVolume == 0) return;
    final usePunch = _random.nextBool();
    _playPooledSound(
      usePunch ? _punchSfxPool : _slapSfxPool,
      fallbackAsset: usePunch ? _punchEffectAsset : _slapEffectAsset,
    );
  }

  Future<AudioPool> _createEffectPool(String assetPath, int maxPlayers) {
    return AudioPool.create(
      source: AssetSource(assetPath),
      minPlayers: 1,
      maxPlayers: maxPlayers,
      playerMode: PlayerMode.lowLatency,
      audioContext: _effectAudioContext,
    );
  }

  void _playPooledSound(AudioPool? pool, {String? fallbackAsset}) {
    if (pool == null) {
      if (fallbackAsset != null) _playOneShotEffect(fallbackAsset);
      return;
    }
    pool
        .start(volume: soundEffectVolume)
        .then((stop) {
          Future<void>.delayed(const Duration(seconds: 2), stop);
          _ensureBgmContinues();
        })
        .catchError((_) {
          if (fallbackAsset != null) _playOneShotEffect(fallbackAsset);
        });
  }

  Future<void> _playOneShotEffect(String assetPath) async {
    if (!_enabled || soundEffectVolume == 0) return;
    final player = AudioPlayer();
    try {
      await player.setAudioContext(_effectAudioContext);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource(assetPath), volume: soundEffectVolume);
      Future<void>.delayed(const Duration(seconds: 2), player.dispose);
      _ensureBgmContinues();
    } catch (_) {
      await player.dispose();
    }
  }

  void _ensureBgmContinues() {
    if (!_enabled || musicVolume == 0) return;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      final player = _bgmPlayer;
      if (player != null && player.state != PlayerState.playing) {
        player.resume().catchError((_) {});
      }
    });
  }

  void dispose() {
    _bgmPlayer?.dispose();
    _voicePlayer?.dispose();
    _regularSfxPool?.dispose();
    _pageTurnSfxPool?.dispose();
    _punchSfxPool?.dispose();
    _slapSfxPool?.dispose();
  }
}
