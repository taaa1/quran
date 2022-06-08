import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'd/chapters.dart';
import 'read.dart';
import 'arabic.dart';
import 'settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool ar = false;

  @override
  void initState() {
    super.initState();
    StreamingSharedPreferences.instance.then((value) {
      final d = value.getBool("ar", defaultValue: false);
      setState(() => ar = d.getValue());
      d.listen((value) => setState(() => ar = value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.quran),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Stg()));
              },
              tooltip: AppLocalizations.of(context)!.settings,
            ),
            IconButton(
                onPressed: () => PackageInfo.fromPlatform().then((v) => showLicensePage(
                    context: context,
                    applicationName: "Qur'an",
                    applicationVersion: v.version,
                    applicationLegalese: AppLocalizations.of(context)!.about2
                  )),
                icon: const Icon(Icons.info_outline),
                tooltip: AppLocalizations.of(context)!.about)
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: Column(
                  children: <Widget>[
                    s(),
                    const Divider(),
                    FutureBuilder<String>(
                      future: DefaultAssetBundle.of(context)
                          .loadString("assets/chapters.json"),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          Chapters js =
                              Chapters.fromJson(jsonDecode(snapshot.data!));
                          Iterable<Chapter> k = js.chapters;
                          List<Widget> a = k
                              .map((p0) => Card(
                                  child: ListTile(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ReadPage(
                                                  surat: p0.latin,
                                                  ind: p0.id - 1))),
                                      leading: Text(p0.id.toString()),
                                      title: Text(ar ? p0.arabic : p0.latin,
                                          style: ar
                                              ? arabic.copyWith(
                                                  fontWeight: FontWeight.bold)
                                              : const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                          textScaleFactor: ar ? 1.5 : null,
                                          locale: ar
                                              ? const Locale('ar')
                                              : const Locale('en')))))
                              .toList();
                          return ResponsiveGridList(
                              horizontalGridMargin: 50,
                              verticalGridMargin: 20,
                              minItemWidth: 300,
                              minItemsPerRow: 1,
                              maxItemsPerRow: 3,
                              shrinkWrap: true,
                              children: a);
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                )))));
  }

  Widget s() {
    return FutureBuilder<StreamingSharedPreferences>(
        future: StreamingSharedPreferences.instance,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PreferenceBuilder<List<String>>(
                preference:
                    snapshot.data!.getStringList("last", defaultValue: []),
                builder: (context, data) {
                  if (data.isNotEmpty) {
                    debugPrint(data.toString());
                    return Column(children: [
                      Text(AppLocalizations.of(context)!.head3,
                          style: Theme.of(context).textTheme.headlineSmall),
                      ResponsiveGridList(
                          children: data.map((e) {
                            var s = e.split(":");
                            s = s
                                .map((value) =>
                                    (int.parse(value) + 1).toString())
                                .toList();
                            return Card(
                                child: ListTile(
                                    title: Text(s.join(":")),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ReadPage(
                                                surat: s[0],
                                                ind: int.parse(s[0]) - 1,
                                                scrollTo: int.parse(s[1]))))));
                          }).toList(),
                          minItemWidth: 300,
                          maxItemsPerRow: 3,
                          shrinkWrap: true,
                          horizontalGridMargin: 50,
                          verticalGridMargin: 20)
                    ]);
                  }
                });
          }
          return const CircularProgressIndicator();
        });
  }
}
