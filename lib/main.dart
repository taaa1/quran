import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quran/d/quran.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran/translations.dart';
import 'package:quran/d/chapters.dart';

void main() {
  runApp(const App());
}

const TextStyle arabic = TextStyle(fontFamily: 'Uthmani');

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => MyApp();
}

class MyApp extends State<App> {
  bool dark = false;

  @override
  void initState() {
    super.initState();

    StreamingSharedPreferences.instance.then((value) {
      final s = value.getBool("dark", defaultValue: false);
      setState(() => dark = s.getValue());
      s.listen((value) => setState(() => dark = value));
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
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<String> _lss;
  List<String>? _last;
  bool ar = false;

  @override
  void initState() {
    super.initState();
    _lss = DefaultAssetBundle.of(context).loadString("assets/chapters.json");
    StreamingSharedPreferences.instance.then((value) {
      final s = value.getStringList("last", defaultValue: []);
      setState(() => _last = s.getValue());
      s.listen((value) => setState(() => _last = value));

      final d = value.getBool("ar", defaultValue: false);
      setState(() => ar = d.getValue());
      d.listen((value) => setState(() => ar = value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Qur'an"),
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
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Info())),
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
                    Text(
                      AppLocalizations.of(context)!.head,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    s(),
                    const Divider(),
                    Text(AppLocalizations.of(context)!.head2,
                        style: Theme.of(context).textTheme.headlineSmall),
                    FutureBuilder<String>(
                      future: _lss,
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
                                          style: ar ? arabic : null,
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
    if (_last != null) {
      List<String>? data = _last;
      if (data != null) {
        if (data.isNotEmpty) {
          debugPrint(data.toString());
          return Column(children: [
            const Divider(),
            Text(AppLocalizations.of(context)!.head3,
                style: Theme.of(context).textTheme.headlineSmall),
            ResponsiveGridList(
                children: data.map((e) {
                  var s = e.split(":");
                  s = s
                      .map((value) => (int.parse(value) + 1).toString())
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
      }
    }

    return Container();
  }
}

class ReadPage extends StatefulWidget {
  const ReadPage(
      {Key? key, required this.surat, required this.ind, this.scrollTo})
      : super(key: key);

  final String surat;
  final int ind;
  final int? scrollTo;

  @override
  State<ReadPage> createState() => _ReadPageS();
}

class _ReadPageS extends State<ReadPage> {
  late Future<String> _data;
  late Future<List<Translation>> _trans;
  List<int> ss = [];
  List list = [];
  String? title;
  Trl? cache;
  bool aus = true;

  @override
  void initState() {
    super.initState();
    _data = DefaultAssetBundle.of(context).loadString("assets/quran.json");
    _trans = loadTrans();
    DefaultAssetBundle.of(context).loadString("assets/chapters.json").then(
        (v) => setState(() => title =
            Chapters.fromJson(jsonDecode(v)).chapters[widget.ind].latin));
    loadTransCache().then((v) => setState(() => cache = v));
    StreamingSharedPreferences.instance.then((v) =>
        setState(() => aus = v.getBool("pos", defaultValue: true).getValue()));
  }

  Future<Trl?> loadTransCache() async {
    final directory = await getApplicationDocumentsDirectory();
    try {
      var s = await File("${directory.path}/quran/translation_cache.json")
          .readAsString();
      return Trl.fromJson(jsonDecode(s));
    } catch (e) {
      return null;
    }
  }

  Future<List<Translation>> loadTrans() async {
    final directory = await getApplicationDocumentsDirectory();

    if (!Directory('${directory.path}/quran/translations/').existsSync()) {
      Directory('${directory.path}/quran/translations/')
          .createSync(recursive: true);
    }

    return Directory('${directory.path}/quran/translations/')
        .listSync()
        .map((e) =>
            Translation.fromJson(jsonDecode(File(e.path).readAsStringSync())))
        .toList();
  }

  void update(int a) async {
    final pref = await StreamingSharedPreferences.instance;
    var s = pref.getStringList('last', defaultValue: []).getValue();
    if (s.any((element) => int.parse(element.split(":")[0]) == widget.ind)) {
      s.removeWhere(
          (element) => int.parse(element.split(":")[0]) == widget.ind);
      s.insert(0, "${widget.ind}:$a");
    } else {
      if (s.isNotEmpty && s.length == 3) s.removeLast();
      s.insert(0, "${widget.ind}:$a");
    }
    pref.setStringList('last', s);
    debugPrint(s.toString());
  }

  @override
  void dispose() {
    super.dispose();
    for (var element in list.toList().asMap().entries) {
      VisibilityDetectorController.instance.forget(Key(element.key.toString()));
    }
  }

  @override
  Widget build(BuildContext build) {
    List<Widget> ac = [];
    if (!aus) {
      ac.add(IconButton(
          onPressed: () {
            update(ss.reduce(min));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.posSaved)));
          },
          icon: const Icon(Icons.bookmark),
          tooltip: AppLocalizations.of(context)!.savePos));
    }

    return Scaffold(
        appBar: AppBar(title: Text(title ?? widget.surat), actions: ac),
        body: SingleChildScrollView(
            child: FutureBuilder(
          future: _data,
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              List<Widget> s =
                  Quran.fromJson(jsonDecode(snapshot.data.toString()))
                      .val
                      .where((element) =>
                          int.parse(element.id.split(":")[0]) - 1 == widget.ind)
                      .map((p0) {
                final int key = int.parse(p0.id.split(":")[1]) - 1;
                var li = GlobalKey();
                list.add(li);
                return Column(key: li, children: [
                  VisibilityDetector(
                      key: Key(key.toString()),
                      onVisibilityChanged: (VisibilityInfo v) {
                        var vi = v.visibleFraction * 100;
                        int key = int.parse((v.key as ValueKey<String>).value);
                        if (vi > 40) {
                          if (!ss.contains(key)) ss.add(key);
                        } else {
                          ss.remove(key);
                        }
                        if (ss.isNotEmpty && aus) update(ss.reduce(min));
                      },
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(children: [
                            ListTile(
                                leading: Text((key + 1).toString()),
                                title: Text(
                                  p0.text + " " + nu((key + 1).toString()),
                                  textScaleFactor: 2,
                                  style: arabic,
                                  textDirection: TextDirection.rtl,
                                  locale: const Locale('ar'),
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: FutureBuilder<List<Translation>>(
                                  future: _trans,
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      WidgetsBinding.instance!
                                          .addPostFrameCallback(
                                              (_) => scroll());
                                      return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: snapshot.data!
                                              .map((e) => Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 16),
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 600),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(e.meta.title,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        Text(e
                                                            .translations[
                                                                p0.i - 1]
                                                            .text
                                                            .replaceAll(
                                                                RegExp(
                                                                    r'\<sup foot\_note\=\"?\d*\"?\>\d*\<\/sup\>'),
                                                                '')), //TODO: show footnotes
                                                        const Divider()
                                                      ])))
                                              .toList());
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                ))
                          ]))),
                  const Divider()
                ]);
              }).toList();

              return ListView(children: s, shrinkWrap: true);
            }

            return const Center(child: CircularProgressIndicator());
          },
        )));
  }

  Future<void> scroll() async {
    if (widget.scrollTo != null) {
      Scrollable.ensureVisible(list[widget.scrollTo! - 1].currentContext);
    }
  }

  String nu(String s) {
    final l = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (var v in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      s = s.replaceAll(v, l[int.parse(v)]);
    }
    return s;
  }
}

class Stg extends StatefulWidget {
  const Stg({Key? key}) : super(key: key);

  @override
  State<Stg> createState() => SettingsPage();
}

class SettingsPage extends State<Stg> {
  bool dm = false;
  bool ar = false;
  bool pos = true;
  List<StreamSubscription> p = [];

  @override
  void initState() {
    super.initState();
    StreamingSharedPreferences.instance.then((value) {
      final s = value.getBool("dark", defaultValue: false);
      setState(() => dm = s.getValue());
      p.add(s.listen((value) => setState(() => dm = value)));

      final d = value.getBool("ar", defaultValue: false);
      setState(() => ar = d.getValue());
      p.add(d.listen((value) => setState(() => ar = value)));

      final o = value.getBool("pos", defaultValue: true);
      setState(() => pos = o.getValue());
      p.add(o.listen((value) => setState(() => pos = value)));
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: SingleChildScrollView(
          child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.translation),
            leading: const Icon(Icons.translate),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TranslationsPage()));
            },
          ),
          SwitchListTile(
              title: Text(AppLocalizations.of(context)!.darkMode),
              secondary: const Icon(Icons.dark_mode),
              value: dm,
              onChanged: (s) => update(s, "dark")),
          SwitchListTile(
              title: Text(AppLocalizations.of(context)!.arabicName),
              secondary: const Icon(Icons.list),
              onChanged: (b) => update(b, "ar"),
              value: ar),
          SwitchListTile(
              title: Text(AppLocalizations.of(context)!.autosavePos),
              secondary: const Icon(Icons.bookmark),
              value: pos,
              onChanged: (b) => update(b, "pos"))
        ],
      )),
    );
  }

  void update(bool b, String c) {
    StreamingSharedPreferences.instance.then((v) => v.setBool(c, b));
  }
}

class Footnotes extends StatefulWidget {
  const Footnotes({Key? key, required this.fn}) : super(key: key);

  final String fn;

  @override
  State<Footnotes> createState() => Fn();
}

class Fn extends State<Footnotes> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconButton(
          onPressed: () => setState(() => open = !open),
          icon: const Icon(Icons.info_outline),
          tooltip: AppLocalizations.of(context)!.footnote),
      open ? Text(widget.fn) : Container()
    ]);
  }
}

class Info extends StatelessWidget {
  const Info({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Tentang")),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
                child: Column(children: [
              const Image(
                  image: AssetImage("icon.png"), width: 140, height: 140),
              Text("Qur'an", style: Theme.of(context).textTheme.headlineMedium),
              Text(AppLocalizations.of(context)!.about2)
            ]))));
  }
}
