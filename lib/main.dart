import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:tiktac_app/screens/home_screen.dart';
import 'package:tiktac_app/services/stopwatch_service.dart';
import 'package:tiktac_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final service = StopwatchService();
  await service.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StopwatchProvider(service)..init(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronómetro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
