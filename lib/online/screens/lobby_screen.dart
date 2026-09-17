import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../online/controller/online_game_controller.dart';
import '../../online/services/auth_service.dart';
import '../../models/player_model.dart';
import '../../wallet/models/stake_level.dart';
import 'online_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final StakeLevel stake;
  const LobbyScreen({super.key, this.stake = StakeLevel.free});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameCtrl     = TextEditingController();
  final _roomCodeCtrl = TextEditingController();
  bool _nameEditing   = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final auth = AuthService();
    _nameCtrl.text = auth.displayName;

    // Connect to server as soon as lobby opens.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<OnlineGameController>();
      await ctrl.connect();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCodeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _listenForGameStart(OnlineGameController ctrl) {
    if (ctrl.phase == OnlinePhase.gameStart ||
        ctrl.phase == OnlinePhase.dealing ||
        ctrl.phase == OnlinePhase.bidding ||
        ctrl.phase == OnlinePhase.waitingBid) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const OnlineGameScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _joinQueue(OnlineGameController ctrl) {
    final auth = AuthService();
    ctrl.joinQueue(auth.displayName, auth.avatarPath, widget.stake);
  }

  void _createPrivate(OnlineGameController ctrl) {
    final auth = AuthService();
    ctrl.createPrivateRoom(auth.displayName, auth.avatarPath);
  }

  void _joinPrivate(OnlineGameController ctrl) {
    final code = _roomCodeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-character room code')),
      );
      return;
    }
    final auth = AuthService();
    ctrl.joinPrivateRoom(auth.displayName, auth.avatarPath, code);
  }

  Future<void> _saveName(OnlineGameController ctrl) async {
    final auth = AuthService();
    await auth.setDisplayName(_nameCtrl.text);
    setState(() => _nameEditing = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OnlineGameController>(
        builder: (context, ctrl, _) {
          // Trigger navigation when game starts.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _listenForGameStart(ctrl);
          });

          return Stack(
            children: [
              // Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/wood_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2C160B), Color(0xFF5C3317), Color(0xFF2C160B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              // Vignette
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: _buildBody(ctrl),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(OnlineGameController ctrl) {
    switch (ctrl.phase) {
      case OnlinePhase.idle:
      case OnlinePhase.connecting:
        return _buildConnecting();

      case OnlinePhase.inQueue:
        return _buildInQueue(ctrl);

      case OnlinePhase.waitingRoom:
        return _buildWaitingRoom(ctrl);

      case OnlinePhase.error:
        return _buildError(ctrl);

      case OnlinePhase.disconnected:
        return _buildDisconnected(ctrl);

      default:
        // game_start / dealing / bidding — navigation will fire via listener
        return _buildConnecting();
    }
  }

  // ── Connecting splash ──────────────────────────────────────────────────────

  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.headerGold),
          const SizedBox(height: 18),
          Text(
            'Connecting to server…',
            style: _labelStyle(),
          ),
        ],
      ),
    );
  }

  // ── Main lobby (profile + mode selection) ─────────────────────────────────

  // _buildLobbyMain kept for future use when direct lobby access is re-enabled.
  // ignore: unused_element
  Widget _buildLobbyMain(OnlineGameController ctrl) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Profile ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: _buildProfileCard(),
              ),
              const SizedBox(width: 24),
              // ── Right: Mode selection ──────────────────────────────────
              Expanded(
                flex: 6,
                child: _buildModeCard(ctrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Consumer<AuthService>(
      builder: (_, auth, __) => _woodPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('YOUR PROFILE',
                style: TextStyle(
                    color: AppTheme.headerGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const SizedBox(height: 14),
            // Avatar picker
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: Player.availableAvatars.take(6).map((av) {
                final sel = auth.avatarPath == av;
                return GestureDetector(
                  onTap: () => auth.setAvatarPath(av),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? AppTheme.activeTurnNeon : Colors.white24,
                        width: sel ? 2.5 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(av, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person, color: Colors.white54, size: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // Name field
            if (_nameEditing)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      maxLength: 16,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.black38,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _saveName(
                          context.read<OnlineGameController>()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        _saveName(context.read<OnlineGameController>()),
                    child: const Icon(Icons.check_circle,
                        color: AppTheme.confirmGreen, size: 26),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => setState(() => _nameEditing = true),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      auth.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, color: AppTheme.headerGold, size: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(OnlineGameController ctrl) {
    return _woodPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CHOOSE MODE',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.headerGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 16),

          // Quick Match
          _actionButton(
            label: '⚡  Quick Match',
            subtitle: 'Auto-match with 3 real players',
            color: const Color(0xFF2EB846),
            onTap: () => _joinQueue(ctrl),
          ),
          const SizedBox(height: 12),

          // Create private
          _actionButton(
            label: '🔒  Create Private Room',
            subtitle: 'Invite friends with a 6-letter code',
            color: const Color(0xFF1976D2),
            onTap: () => _createPrivate(ctrl),
          ),
          const SizedBox(height: 12),

          // Join private
          const Text('Or enter a room code:',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'ABC123',
                    hintStyle: const TextStyle(
                        color: Colors.white30, letterSpacing: 4),
                    filled: true,
                    fillColor: Colors.black38,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _joinPrivate(ctrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE89945),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('JOIN',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── In queue ───────────────────────────────────────────────────────────────

  Widget _buildInQueue(OnlineGameController ctrl) {
    return Center(
      child: _woodPanel(
        maxWidth: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('FINDING PLAYERS',
                style: TextStyle(
                    color: AppTheme.headerGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppTheme.headerGold),
            ),
            const SizedBox(height: 16),
            Text(
              ctrl.statusMessage,
              textAlign: TextAlign.center,
              style: _labelStyle(),
            ),
            const SizedBox(height: 20),
            _secondaryButton('Cancel', () {
              ctrl.disconnect();
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  // ── Waiting room ───────────────────────────────────────────────────────────

  Widget _buildWaitingRoom(OnlineGameController ctrl) {
    return Center(
      child: _woodPanel(
        maxWidth: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('WAITING ROOM',
                    style: TextStyle(
                        color: AppTheme.headerGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                if (ctrl.roomCode.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: ctrl.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Room code copied!'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.headerGold),
                      ),
                      child: Row(
                        children: [
                          Text(
                            ctrl.roomCode,
                            style: const TextStyle(
                                color: AppTheme.headerGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy,
                              color: AppTheme.headerGold, size: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            // 4 seat slots
            ...List.generate(4, (i) => _buildSeatRow(ctrl, i)),
            const SizedBox(height: 18),
            Text(
              ctrl.statusMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _secondaryButton('Leave', () {
              ctrl.disconnect();
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatRow(OnlineGameController ctrl, int i) {
    final seat = ctrl.lobbySeats.length > i
        ? ctrl.lobbySeats.firstWhere(
            (s) => s['seat'] == i,
            orElse: () => {'seat': i, 'empty': true},
          )
        : {'seat': i, 'empty': true};

    final isEmpty = seat['empty'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.black26 : Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isEmpty ? Colors.white12 : AppTheme.headerGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEmpty ? Colors.white10 : const Color(0xFF5C3317),
              border: Border.all(
                  color: isEmpty ? Colors.white24 : AppTheme.headerGold),
            ),
            child: isEmpty
                ? const Icon(Icons.person_outline,
                    color: Colors.white30, size: 18)
                : ClipOval(
                    child: Image.asset(
                      (seat['avatar'] as String?) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.person, color: Colors.white54, size: 18),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEmpty ? 'Waiting…' : (seat['name'] as String? ?? 'Player'),
              style: TextStyle(
                color: isEmpty ? Colors.white30 : Colors.white,
                fontSize: 13,
                fontWeight:
                    isEmpty ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
          if (!isEmpty)
            const Icon(Icons.check_circle, color: AppTheme.confirmGreen, size: 18),
        ],
      ),
    );
  }

  // ── Error / disconnected ───────────────────────────────────────────────────

  Widget _buildError(OnlineGameController ctrl) {
    return Center(
      child: _woodPanel(
        maxWidth: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              ctrl.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _actionButton(
              label: 'Try Again',
              color: AppTheme.confirmGreen,
              onTap: () async {
                ctrl.disconnect();
                await ctrl.connect();
              },
            ),
            const SizedBox(height: 8),
            _secondaryButton('Back', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnected(OnlineGameController ctrl) =>
      _buildError(ctrl);  // same UI, different message

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _woodPanel({required Widget child, double? maxWidth}) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 560),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF3E1F0D).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.headerGold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(
      color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500);
}
