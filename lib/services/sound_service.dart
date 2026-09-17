import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';

/// Sound manager for Callbreak sound effects + background music.
class SoundService {
  SoundService._() {
    _initPlayers();
  }

  static final SoundService instance = SoundService._();
  static bool disableAudio = false;

  final List<AudioPlayer> _sfxPool = [];
  int _poolIndex = 0;
  static const int _poolSize = 4;

  // Dedicated player for looping background music
  AudioPlayer? _musicPlayer;
  bool _musicPlaying = false;

  bool isMuted = false;

  void _initPlayers() {
    if (disableAudio ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    try {
      for (int i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        p.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }
      _musicPlayer = AudioPlayer();
      _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      _musicPlayer!.setVolume(0.35); // subtle background volume
    } catch (_) {}
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      _musicPlayer?.pause();
    } else if (_musicPlaying) {
      _musicPlayer?.resume();
    }
  }

  // ── Background music ───────────────────────────────────────────────────────

  /// Start looping background music. Call from HomeScreen / GameScreen.
  Future<void> startMusic() async {
    if (_musicPlayer == null || isMuted) return;
    try {
      _musicPlaying = true;
      await _musicPlayer!.play(AssetSource('sounds/bg_music.mp3'));
    } catch (_) {}
  }

  /// Switch to the in-game table music track.
  Future<void> startTableMusic() async {
    if (_musicPlayer == null || isMuted) return;
    try {
      _musicPlaying = true;
      await _musicPlayer!.stop();
      await _musicPlayer!.play(AssetSource('sounds/bg_music_table.ogg'));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    _musicPlaying = false;
    await _musicPlayer?.stop();
  }

  // ── SFX ───────────────────────────────────────────────────────────────────

  Future<void> _play(String fileName) async {
    if (isMuted || _sfxPool.isEmpty) return;
    try {
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource('sounds/$fileName'));
    } catch (_) {}
  }

  void playCardTap()     => _play('card_tap.wav');
  void playCardSlide()   => _play('card_slide.wav');
  void playCardPlace()   => _play('card_place.wav');
  void playCardFan()     => _play('card_fan.wav');
  void playTrickWin()    => _play('trick_win.wav');
  void playButtonClick() => _play('btn_click.wav');
  void playCoin()        => _play('coin.wav');
  void playWin()         => _play('win.wav');
  void playLose()        => _play('lose.mp3');   // ← NEW: game lost sound
  void playWhoosh()      => _play('whoosh.wav');
  void playGong()        => _play('gong.wav');
  void playChips()       => _play('chips.wav');

  void dispose() {
    for (final p in _sfxPool) {
      p.dispose();
    }
    _musicPlayer?.dispose();
  }
}
