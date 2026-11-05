import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'themes/app_theme.dart';
import 'utils/media_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStore.init();
  await Hive.initFlutter();
  await Hive.openBox('sessions_box');
  await Hive.openBox('settings_box');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FakeChatSimulatorApp());
  // "Remove ads" first so a buyer never sees one; consent + ads in the background, never blocks the start
  PurchaseService.instance.init().whenComplete(AdService.instance.init);
}

class FakeChatSimulatorApp extends StatelessWidget {
  const FakeChatSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Fake Chat Simulator',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DashboardScreen(),
            builder: (context, child) {
              return Directionality(
                textDirection: themeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
