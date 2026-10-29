import 'package:flutter/material.dart';
import 'controllers/pos_controller.dart';
import 'models/pos_models.dart';
import 'screens/client_kitchen_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/server_pos_screen.dart';
import 'theme/manga_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashPosDogosApp());
}

class FlashPosDogosApp extends StatefulWidget {
  const FlashPosDogosApp({super.key});

  @override
  State<FlashPosDogosApp> createState() => _FlashPosDogosAppState();
}

class _FlashPosDogosAppState extends State<FlashPosDogosApp> {
  late final PosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PosController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dogos El Pa · POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: MangaColors.bgCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MangaColors.primaryOrange,
          primary: MangaColors.primaryOrange,
          secondary: MangaColors.accentYellow,
          surface: MangaColors.surfaceWhite,
        ),
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          switch (_controller.appMode) {
            case AppMode.server:
              return ServerPosScreen(controller: _controller);
            case AppMode.client:
              return ClientKitchenScreen(controller: _controller);
            case AppMode.unselected:
              return ModeSelectionScreen(controller: _controller);
          }
        },
      ),
    );
  }
}
