import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

const TextStyle arabic = TextStyle(fontFamily: 'Uthmani');

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qur\'an',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
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

  @override
  void initState() {
    super.initState();
    _lss = DefaultAssetBundle.of(context).loadString("assets/quran.xml");
    StreamingSharedPreferences.instance.then((value) {
      final s = value.getStringList("last", defaultValue: []);
      setState(() => _last = s.getValue());
      s.listen((value) => setState(() => _last = value));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
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
                          Iterable k = XmlDocument.parse(snapshot.data!)
                              .getElement("quran")!
                              .childElements;
                          List<Widget> a = k
                              .toList()
                              .asMap()
                              .entries
                              .map((p0) => Card(
                                  child: InkWell(
                                      splashColor: Colors.green,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ReadPage(
                                                    surat: p0.value
                                                        .getAttribute("name")!,
                                                    ind: p0.key)));
                                      },
                                      child: ListTile(
                                          title: Text(
                                              p0.value.getAttribute("name")!,
                                              style: arabic,
                                              textScaleFactor: 1.5,
                                              textAlign: TextAlign.right)))))
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
  late Future<List<XmlDocument>> _trans;
  List<int> ss = [];
  List list = [];
  String? title;

  @override
  void initState() {
    super.initState();
    _data = DefaultAssetBundle.of(context).loadString("assets/quran.xml");
    _trans = loadTrans();
    _data.then((v) => setState(()=>title=XmlDocument.parse(v).getElement("quran")!.childElements.elementAt(widget.ind).getAttribute("name")));
  }

  Future<List<XmlDocument>> loadTrans() async {
    final directory = await getApplicationDocumentsDirectory();

    if (!Directory('${directory.path}/quran/translations/').existsSync()) {
      Directory('${directory.path}/quran/translations/')
          .createSync(recursive: true);
    }

    return Directory('${directory.path}/quran/translations/')
        .listSync()
        .map((e) => XmlDocument.parse(File(e.path).readAsStringSync()))
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
    return Scaffold(
        appBar: AppBar(title: Text(title??widget.surat, style: arabic)),
        body: SingleChildScrollView(
            child: FutureBuilder(
          future: _data,
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              List<Widget> s = XmlDocument.parse(snapshot.data.toString())
                  .getElement("quran")!
                  .childElements
                  .elementAt(widget.ind)
                  .childElements
                  .toList()
                  .asMap()
                  .entries
                  .map((p0) {
                var li = GlobalKey();
                list.add(li);
                return Column(key: li, children: [
                  VisibilityDetector(
                      key: Key(p0.key.toString()),
                      onVisibilityChanged: (VisibilityInfo v) {
                        var vi = v.visibleFraction * 100;
                        int key = int.parse((v.key as ValueKey<String>).value);
                        if (vi > 40) {
                          if (!ss.contains(key)) ss.add(key);
                        } else {
                          ss.remove(key);
                        }
                        if (ss.isNotEmpty) update(ss.reduce(min));
                      },
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(children: [
                            ListTile(
                                leading: Text((p0.key + 1).toString()),
                                title: Text(
                                  p0.value.getAttribute("text")!,
                                  textScaleFactor: 2,
                                  style: arabic,
                                  textDirection: TextDirection.rtl,
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: FutureBuilder(
                                  future: _trans,
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      WidgetsBinding.instance!
                                          .addPostFrameCallback(
                                              (_) => scroll());
                                      return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: (snapshot.data
                                                  as List<XmlDocument>)
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
                                                        Text(
                                                            "${e.getElement('translation_root')!.getElement('meta')!.getElement("language")!.innerText} — ${e.getElement('translation_root')!.getElement('meta')!.getElement("id")!.innerText}",
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        Text(e
                                                            .getElement(
                                                                "translation_root")!
                                                            .getElement(
                                                                "sura_list")!
                                                            .findAllElements(
                                                                "sura")
                                                            .elementAt(
                                                                widget.ind)
                                                            .findAllElements(
                                                                "aya")
                                                            .elementAt(p0.key)
                                                            .getElement(
                                                                "translation")!
                                                            .innerText),
                                                        (e
                                                                .getElement(
                                                                    "translation_root")!
                                                                .getElement(
                                                                    "sura_list")!
                                                                .findAllElements(
                                                                    "sura")
                                                                .elementAt(
                                                                    widget.ind)
                                                                .findAllElements(
                                                                    "aya")
                                                                .elementAt(
                                                                    p0.key)
                                                                .getElement(
                                                                    "footnotes")!
                                                                .innerText
                                                                .isNotEmpty)
                                                            ? Footnotes(
                                                                fn: e
                                                                    .getElement(
                                                                        "translation_root")!
                                                                    .getElement(
                                                                        "sura_list")!
                                                                    .findAllElements(
                                                                        "sura")
                                                                    .elementAt(
                                                                        widget
                                                                            .ind)
                                                                    .findAllElements(
                                                                        "aya")
                                                                    .elementAt(
                                                                        p0.key)
                                                                    .getElement(
                                                                        "footnotes")!
                                                                    .innerText)
                                                            : Container(),
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
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
          )
        ],
      )),
    );
  }
}

class TranslationsPage extends StatefulWidget {
  const TranslationsPage({Key? key}) : super(key: key);

  @override
  State<TranslationsPage> createState() => _Tp();
}

class _Tp extends State<TranslationsPage> {
  late Future<Trl> _json;
  List<XmlDocument>? _installed;
  StreamSubscription? watch;

  Future<Trl> fetchTranslationList() async {
    final res = await http
        .get(Uri.parse('https://quranenc.com/api/v1/translations/list'));

    //check if 200
    return Trl.fromJson(jsonDecode(res.body));
  }

  Future<List<XmlDocument>> getInstalled() async {
    final directory = await getApplicationDocumentsDirectory();

    if (!Directory('${directory.path}/quran/translations/').existsSync()) {
      Directory('${directory.path}/quran/translations/')
          .createSync(recursive: true);
    }

    return Directory('${directory.path}/quran/translations/')
        .listSync()
        .map((e) => XmlDocument.parse(File(e.path).readAsStringSync()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _json = fetchTranslationList();
    getInstalled().then((value) => setState(() => _installed = value));
    getApplicationDocumentsDirectory().then((v) {
      watch =
          Directory('${v.path}/quran/translations/').watch().listen((event) {
        getInstalled().then((value) => setState(() => _installed = value));
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    watch?.cancel();
  }

  void delete(String key) async {
    final directory = await getApplicationDocumentsDirectory();

    File('${directory.path}/quran/translations/$key.xml').deleteSync();
  }

  @override
  Widget build(BuildContext context) {
    late Widget installed;
    if (_installed != null) {
      List<Widget> s = (_installed as List<XmlDocument>)
          .map((e) => Card(
              key: Key(e
                  .getElement("translation_root")!
                  .getElement("meta")!
                  .getElement("id")!
                  .innerText),
              child: Column(children: [
                ListTile(
                  title: Text(e
                      .getElement("translation_root")!
                      .getElement("meta")!
                      .getElement("language")!
                      .innerText),
                  leading: const Icon(Icons.translate),
                  subtitle: Text(e
                      .getElement("translation_root")!
                      .getElement("meta")!
                      .getElement("id")!
                      .innerText),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => delete(e
                            .getElement("translation_root")!
                            .getElement("meta")!
                            .getElement("id")!
                            .innerText),
                        child: Text(AppLocalizations.of(context)!.delete))
                  ],
                )
              ])))
          .toList();
      installed = (s.isEmpty)
          ? Text(AppLocalizations.of(context)!.noInstalledTranslations,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.subtitle1)
          : ResponsiveGridList(
              horizontalGridMargin: 50,
              verticalGridMargin: 10,
              minItemWidth: 300,
              minItemsPerRow: 1,
              maxItemsPerRow: 3,
              shrinkWrap: true,
              children: s);
    } else {
      installed = const CircularProgressIndicator();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translation),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Column(
                children: [
                  Column(
                    children: [
                      Text(AppLocalizations.of(context)!.installed,
                          style: Theme.of(context).textTheme.headlineMedium),
                      installed
                    ],
                  ),
                  const Divider(),
                  Column(children: [
                    Text(AppLocalizations.of(context)!.available,
                        style: Theme.of(context).textTheme.headlineMedium),
                    FutureBuilder(
                        future: _json,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            List<Widget> s = (snapshot.data! as Trl)
                                .translations
                                .map((p0) => TranslationWidget(p0: p0))
                                .toList();

                            return ResponsiveGridList(
                                horizontalGridMargin: 50,
                                verticalGridMargin: 10,
                                minItemWidth: 300,
                                minItemsPerRow: 1,
                                maxItemsPerRow: 4,
                                shrinkWrap: true,
                                children: s);
                          }

                          return const CircularProgressIndicator();
                        })
                  ])
                ],
              ),
            )));
  }
}

class TranslationWidget extends StatefulWidget {
  const TranslationWidget({Key? key, required this.p0}) : super(key: key);

  final TranslationList p0;

  @override
  State<TranslationWidget> createState() => _TranslationWidget();
}

class _TranslationWidget extends State<TranslationWidget> {
  bool _isLoading = false;

  Future download(String key) async {
    final directory = await getApplicationDocumentsDirectory();
    if (!Directory('${directory.path}/quran/translations/').existsSync()) {
      Directory('${directory.path}/quran/translations/')
          .createSync(recursive: true);
    }
    final file = File('${directory.path}/quran/translations/$key.xml');
    final translation = await http
        .get(Uri.parse("https://quranenc.com/en/home/download/xml/$key"));
    file.writeAsStringSync(translation.body);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
            leading: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.download),
            title: Text(widget.p0.title, overflow: TextOverflow.ellipsis),
            subtitle: Text(widget.p0.description,
                overflow: TextOverflow.ellipsis, maxLines: 3),
            onTap: () {
              setState(() => _isLoading = true);
              download(widget.p0.key)
                  .then((_) => setState(() => _isLoading = false));
            },
            isThreeLine: true));
  }
}

class TranslationList {
  final String title;
  final String key;
  final String description;

  const TranslationList(
      {required this.key, required this.title, required this.description});

  factory TranslationList.fromJson(Map<String, dynamic> json) {
    return TranslationList(
        key: json['key'],
        title: json['title'],
        description: json['description']);
  }
}

class Trl {
  final List<TranslationList> translations;

  const Trl({required this.translations});

  factory Trl.fromJson(Map<String, dynamic> json) {
    return Trl(
        translations: (json['translations'] as List)
            .map((p0) => TranslationList.fromJson(p0))
            .toList());
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
              Text("Qur'an", style: Theme.of(context).textTheme.headlineMedium),
              Text(AppLocalizations.of(context)!.about1),
              Text(AppLocalizations.of(context)!.about2)
            ]))));
  }
}
