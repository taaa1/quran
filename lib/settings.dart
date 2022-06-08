import 'dart:async';

import 'package:flutter/material.dart';
import 'i18n.dart';
import 'package:intl/intl.dart' as intl;
import 'arabic.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'translations.dart';

class Stg extends StatefulWidget {
  const Stg({Key? key}) : super(key: key);

  @override
  State<Stg> createState() => SettingsPage();
}

class SettingsPage extends State<Stg> {
  double size = 2;
  List<StreamSubscription> p = [];

  @override
  void initState() {
    super.initState();
    StreamingSharedPreferences.instance.then((value) {
      final z = value.getDouble("asize", defaultValue: 2);
      setState(() => size = z.getValue());
      p.add(z.listen((value) => setState(() => size = value)));
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (var element in p) {
      element.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = lang.entries.toList();
    s.sort((a, b) => a.value.compareTo(b.value));
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
        body: SingleChildScrollView(
            child: FutureBuilder<StreamingSharedPreferences>(
                future: StreamingSharedPreferences.instance,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final pref = snapshot.data!;

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title:
                              Text(AppLocalizations.of(context)!.translation),
                          leading: const Icon(Icons.translate),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const TranslationsPage()));
                          },
                        ),
                        PreferenceBuilder<bool>(
                            preference:
                                pref.getBool("dark", defaultValue: false),
                            builder: (context, d) => SwitchListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.darkMode),
                                secondary: const Icon(Icons.dark_mode),
                                value: d,
                                onChanged: (s) => pref.setBool("dark", s))),
                        PreferenceBuilder<bool>(
                            preference: pref.getBool("ar", defaultValue: false),
                            builder: (context, d) => SwitchListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.arabicName),
                                secondary: const Icon(Icons.list),
                                onChanged: (b) => pref.setBool("ar", b),
                                value: d)),
                        PreferenceBuilder<bool>(
                            preference: pref.getBool("pos", defaultValue: true),
                            builder: (context, d) => SwitchListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.autosavePos),
                                secondary: const Icon(Icons.bookmark),
                                value: d,
                                onChanged: (b) => pref.setBool("pos", b))),
                        ListTile(
                            title: Text(AppLocalizations.of(context)!.textSize),
                            leading: const Icon(Icons.format_size),
                            subtitle: Text(size.toString()),
                            onTap: () => showDialog<double>(
                                context: context,
                                builder: (ctx) =>
                                    SizeDialog(s: size)).then(
                                (value) => pref.setDouble("asize", value!))),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.quran_text),
                          leading: const Icon(Icons.font_download),
                          onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .quran_text),
                                    children: [
                                      option(AppLocalizations.of(context)!.uthmani, 0),
                                      option(AppLocalizations.of(context)!.imlaei, 1)
                                    ],
                                  )),
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.language),
                          leading: const Icon(Icons.language),
                          onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                    title: Text(
                                        AppLocalizations.of(context)!.language),
                                    children: s
                                        .map((v) => SimpleDialogOption(
                                            child: Text(lang[intl.Intl
                                                    .canonicalizedLocale(
                                                        v.key)] ??
                                                ""),
                                            onPressed: () {
                                              StreamingSharedPreferences
                                                  .instance
                                                  .then((val) => val.setString(
                                                      "lang",
                                                      intl.Intl
                                                          .canonicalizedLocale(
                                                              v.key)));
                                              Navigator.pop(context);
                                            }))
                                        .toList(),
                                  )),
                        )
                      ],
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                })));
  }

  void update(bool b, String c) {
    StreamingSharedPreferences.instance.then((v) => v.setBool(c, b));
  }

  SimpleDialogOption option(String text, int value) {
    return SimpleDialogOption(
        child: Text(text),
        onPressed: () {
          StreamingSharedPreferences.instance
              .then((val) => val.setInt("text_t", value));
          Navigator.pop(context);
        });
  }
}

class SizeDialog extends StatefulWidget {
  const SizeDialog({Key? key, required this.s}) : super(key: key);

  final double s;

  @override
  State<SizeDialog> createState() => _SizeDialog();
}

class _SizeDialog extends State<SizeDialog> {
  double s = 2;

  @override
  void initState() {
    super.initState();

    setState(() => s = widget.s);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
            width: 400,
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(AppLocalizations.of(context)!.textSize,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.headline6),
              Text(
                t,
                textScaleFactor: s,
                style: arabic,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
              ),
              Slider(
                  value: s,
                  onChanged: (v) => setState(() => s = v),
                  min: 1,
                  max: 3,
                  divisions: 10,
                  autofocus: true,
                  label: s.toString()),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => Navigator.pop(context, s),
                      child: Text(AppLocalizations.of(context)!.ok)))
            ])));
  }
}
