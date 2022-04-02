import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

const TextStyle arabic = TextStyle(fontFamily: 'Uthmani');

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qur\'an',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
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

  @override
  void initState() {
    super.initState();
    _lss = DefaultAssetBundle.of(context).loadString("assets/quran.xml");
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
              tooltip: "Pengaturan",
            )
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: Column(
                  children: <Widget>[
                    Text(
                      'Mau baca apa hari ini?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
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
                              verticalGridMargin: 50,
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
}

class ReadPage extends StatefulWidget {
  const ReadPage({Key? key, required this.surat, required this.ind})
      : super(key: key);

  final String surat;
  final int ind;

  @override
  State<ReadPage> createState() => _ReadPageS();
}

class _ReadPageS extends State<ReadPage> {
  late Future<String> _data;

  @override
  void initState() {
    super.initState();
    _data = DefaultAssetBundle.of(context).loadString("assets/quran.xml");
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.surat, style: arabic),
        ),
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
                  .map((p0) => Column(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                                leading: Text((p0.key + 1).toString()),
                                title: Text(
                                  p0.value.getAttribute("text")!,
                                  textScaleFactor: 2,
                                  style: arabic,
                                  textDirection: TextDirection.rtl,
                                ))),
                        const Divider()
                      ]))
                  .toList();
              return ListView(children: s, shrinkWrap: true);
            }

            return const Center(child: CircularProgressIndicator());
          },
        )));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: SingleChildScrollView(
          child: ListView(
        shrinkWrap: true,
        children: [
          SettingsItem(
            name: "Terjemahan",
            icon: const Icon(Icons.translate),
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

class SettingsItem extends StatelessWidget {
  const SettingsItem(
      {Key? key, required this.name, required this.icon, required this.onTap})
      : super(key: key);

  final String name;
  final Icon icon;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(name), leading: icon, onTap: onTap);
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
      Directory('${v.path}/quran/translations/').watch().listen((event) {
        getInstalled().then((value) => setState(() => _installed = value));
      });
    });
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
                    TextButton(onPressed: () => delete(e
                      .getElement("translation_root")!
                      .getElement("meta")!
                      .getElement("id")!
                      .innerText), child: const Text("Hapus"))
                  ],
                )
              ])))
          .toList();
      installed = (s.isEmpty)
          ? Text("Belum ada terjemahan yang terpasang.\nPilih terjemahan di bawah untuk memasang.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1)
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
          title: const Text("Terjemahan"),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Column(
                children: [
                  Column(
                    children: [
                      Text("Terpasang",
                          style: Theme.of(context).textTheme.headlineMedium),
                      installed
                    ],
                  ),
                  const Divider(),
                  Column(children: [
                    Text("Tersedia",
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
