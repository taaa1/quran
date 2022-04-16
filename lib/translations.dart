import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class TranslationsPage extends StatefulWidget {
  const TranslationsPage({Key? key}) : super(key: key);

  @override
  State<TranslationsPage> createState() => _Tp();
}

class _Tp extends State<TranslationsPage> {
  late Future<Trl> _json;
  List<TranslationList>? _installed;
  StreamSubscription? watch;

  Future<Trl> fetchTranslationList() async {
    final res = await http
        .get(Uri.parse('https://api.quran.com/api/v4/resources/translations'));

    //check if 200
    return Trl.fromJson(jsonDecode(res.body));
  }

  Future<List<TranslationList>> getInstalled() async {
    final directory = await getApplicationDocumentsDirectory();

    if (!Directory('${directory.path}/quran/translations/').existsSync()) {
      Directory('${directory.path}/quran/translations/')
          .createSync(recursive: true);
    }

    return Directory('${directory.path}/quran/translations/')
        .listSync()
        .map((e) => TranslationList.fromMeta(
            jsonDecode(File(e.path).readAsStringSync())))
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

  @override
  Widget build(BuildContext context) {
    late Widget installed;
    if (_installed != null) {
      List<Widget> s = _installed!.map((e) => Installed(e: e)).toList();
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
                            final so = (snapshot.data! as Trl).translations;
                            so.sort((a, b) => a.title.compareTo(b.title));
                            List<Widget> s = so
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
    final file = File('${directory.path}/quran/translations/$key.json');
    final translation = await http
        .get(Uri.parse("https://api.quran.com/api/v4/quran/translations/$key"));
    file.writeAsStringSync(translation.body);
  }

  @override
  Widget build(BuildContext context) {
    String s = widget.p0.language!;
    s = s[0].toUpperCase() + s.substring(1);
    return Card(
        child: ListTile(
            leading: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.download),
            title: Text(widget.p0.title, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                (widget.p0.description != s
                    ? AppLocalizations.of(context)!
                        .translationDesc(s, widget.p0.description)
                    : s),
                overflow: TextOverflow.ellipsis,
                maxLines: 3),
            onTap: () {
              setState(() => _isLoading = true);
              download(widget.p0.key)
                  .then((_) => setState(() => _isLoading = false));
            },
            isThreeLine: true));
  }
}

class Installed extends StatefulWidget {
  const Installed({required this.e}) : super();

  final TranslationList e;

  @override
  State<Installed> createState() => _Installed();
}

class _Installed extends State<Installed> {
  List<String> s = [];
  StreamSubscription? p;

  @override
  void initState() {
    super.initState();
    StreamingSharedPreferences.instance.then((v) {
      final ls = v.getStringList("disabledt", defaultValue: []);
      setState(() => s = ls.getValue());
      p = ls.listen((value) => setState(() => s = value));
    });
  }

  @override
  void dispose() {
    super.dispose();
    p?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        key: Key(widget.e.key),
        child: Column(children: [
          ListTile(
            title: Text(widget.e.title),
            leading: const Icon(Icons.translate),
            subtitle: Text(widget.e.description),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Switch(value: !s.contains(widget.e.key), onChanged: tog),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => delete(widget.e.key),
                    child: Text(AppLocalizations.of(context)!.delete))
              ],
            )
          ])
        ]));
  }

  void tog(bool m) async {
    if (m) {
      s.remove(widget.e.key);
    } else {
      if (!s.contains(widget.e.key)) s.add(widget.e.key);
    }
    StreamingSharedPreferences.instance
        .then((v) => v.setStringList("disabledt", s));
  }

  void delete(String key) async {
    final directory = await getApplicationDocumentsDirectory();

    File('${directory.path}/quran/translations/$key.json').deleteSync();
  }
}

class TranslationList {
  final String title;
  final String key;
  final String description;
  final String? language;

  const TranslationList(
      {required this.key,
      required this.title,
      required this.description,
      this.language});

  factory TranslationList.fromJson(Map<String, dynamic> json) {
    return TranslationList(
        key: json['id'].toString(),
        title: json['name'],
        description: json['author_name'],
        language: json['language_name']);
  }

  factory TranslationList.fromMeta(Map<String, dynamic> json) {
    return TranslationList(
        key: json['meta']['filters']['resource_id'].toString(),
        title: json['meta']['translation_name'],
        description: json['meta']['author_name']);
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

class Translation {
  final List<Tr> translations;
  final TranslationList meta;
  const Translation({required this.translations, required this.meta});
  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
        translations:
            json['translations'].map<Tr>((v) => Tr.fromJson(v)).toList(),
        meta: TranslationList.fromMeta(json));
  }
}

class Tr {
  final String text;
  const Tr({required this.text});
  factory Tr.fromJson(Map<String, dynamic> json) {
    return Tr(text: json['text']);
  }
}
