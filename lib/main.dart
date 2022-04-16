import 'package:flutter/material.dart';
import 'home.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'i18n.dart' as i;

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => MyApp();
}

class MyApp extends State<App> {
  bool dark = false;
  String lang = "en";

  @override
  void initState() {
    super.initState();

    StreamingSharedPreferences.instance.then((value) {
      final s = value.getBool("dark", defaultValue: false);
      setState(() => dark = s.getValue());
      s.listen((value) => setState(() => dark = value));

      final l = value.getString("lang", defaultValue: "en");
      setState(() => lang = l.getValue());
      l.listen((value) => setState(() => lang = value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qur\'an',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(primarySwatch: Colors.green),
      darkTheme:
          ThemeData(primarySwatch: Colors.green, brightness: Brightness.dark),
      home: const MyHomePage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: i.lang.keys.map((e) => Locale(e)),
      locale: Locale(lang),
    );
  }
}