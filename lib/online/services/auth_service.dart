import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the local player identity:
///   - Signs in anonymously via Firebase Auth (gives us a stable UID across sessions)
///   - Persists the chosen display name and avatar locally via SharedPreferences
///   - Optionally updates the Firebase displayName so it shows up in logs
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _keyDisplayName = 'online_display_name';
  static const _keyAvatarPath  = 'online_avatar_path';

  User? _user;
  String _displayName = 'Player';
  String _avatarPath  = 'assets/images/avatars/you.png';
  bool _ready = false;

  User?   get user        => _user;
  String  get displayName => _displayName;
  String  get avatarPath  => _avatarPath;
  bool    get isReady     => _ready;
  bool    get isSignedIn  => _user != null;

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Call once from main() after Firebase.initializeApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString(_keyDisplayName) ?? 'Player';
    _avatarPath  = prefs.getString(_keyAvatarPath)  ?? 'assets/images/avatars/you.png';

    // Re-use existing anonymous session or sign in fresh.
    _user = FirebaseAuth.instance.currentUser;
    _user ??= (await FirebaseAuth.instance.signInAnonymously()).user;

    // Push display name to Firebase profile so it's visible in analytics.
    if (_user != null && _user!.displayName != _displayName) {
      await _user!.updateDisplayName(_displayName);
    }

    _ready = true;
    notifyListeners();
  }

  // ── Update profile ─────────────────────────────────────────────────────────

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim().isEmpty ? 'Player' : name.trim();
    _displayName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, trimmed);
    await _user?.updateDisplayName(trimmed);
    notifyListeners();
  }

  Future<void> setAvatarPath(String path) async {
    _avatarPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarPath, path);
    notifyListeners();
  }

  // ── Sign out (mostly for testing) ─────────────────────────────────────────

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user  = null;
    _ready = false;
    notifyListeners();
  }
}
