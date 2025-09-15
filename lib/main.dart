import 'package:flutter/material.dart';
import 'core/app_navigator.dart';
import 'l10n/strings.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (_) => t.game.title,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocale.values.map((locale) => locale.flutterLocale),
    home: const AppNavigator(),
  );
}
