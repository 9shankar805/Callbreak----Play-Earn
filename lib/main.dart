import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controller/game_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'online/services/auth_service.dart';
import 'wallet/services/wallet_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialise services before first frame
  await WalletService().init();

  // Firebase auth — wrap in try/catch so offline dev still works
  try {
    await AuthService().init();
  } catch (_) {}

  runApp(const CallbreakApp());
}

class CallbreakApp extends StatelessWidget {
  const CallbreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameController()),
        // Wallet + Auth are singletons — expose them app-wide
        ChangeNotifierProvider.value(value: WalletService()),
        ChangeNotifierProvider.value(value: AuthService()),
      ],
      child: MaterialApp(
        title: 'Callbreak',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
