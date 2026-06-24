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
  AudioPlayer? _bgmPlayer;
  BgmTrack selectedBgm = BgmTrack.cozyNanhe2;
  double musicVolume = 0.7;
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

  void dispose() {
    _bgmPlayer?.dispose();
  }
}
