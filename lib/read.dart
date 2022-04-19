import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'd/quran.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'translations.dart';
import 'd/chapters.dart';
import 'arabic.dart';
import 'fn.dart';

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
  List<int> ss = [];
  List list = [];
  String? title;
  bool aus = true;
  double size = 2;
  bool ar = false;
  bool ha = true;
  List<String> dis = [];
  String next = "";
  String prev = "";

  @override
  void initState() {
    super.initState();
    StreamingSharedPreferences.instance.then((v) {
      setState(() {
        aus = v.getBool("pos", defaultValue: true).getValue();
        size = v.getDouble("asize", defaultValue: 2).getValue();
        ar = v.getBool("ar", defaultValue: false).getValue();
        dis = v.getStringList("disabledt", defaultValue: []).getValue();
      });
      updateTitle();
    });
  }

  void updateTitle() {
    DefaultAssetBundle.of(context).loadString("assets/chapters.json").then((v) {
      final s = Chapters.fromJson(jsonDecode(v)).chapters;
      final k = s[widget.ind];
      setState(() {
        title = ar ? k.arabic : k.latin;
        ha = k.pre;
        if(widget.ind < 113) {
          final n = s[widget.ind + 1];
          next = ar ? n.arabic : n.latin;
        }
        if(widget.ind > 0) {
          final p = s[widget.ind - 1];
          prev = ar ? p.arabic : p.latin;
        }
      });
    });
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
        appBar: AppBar(
            title: Text(title ?? widget.surat,
                style: ar ? arabic : null, textScaleFactor: ar ? 1.5 : null),
            actions: ac),
        body: SingleChildScrollView(
            child: Column(children: [
          ha
              ? Column(children: [
                  Text(
                    t,
                    textScaleFactor: size,
                    style: arabic,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                  ),
                  const Divider()
                ])
              : Container(),
          FutureBuilder(
            future: DefaultAssetBundle.of(context).loadString("assets/quran.json"),
            builder: (ctx, snapshot) {
              if (snapshot.hasData) {
                List<Widget> s = Quran.fromJson(
                        jsonDecode(snapshot.data.toString()))
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
                          int key =
                              int.parse((v.key as ValueKey<String>).value);
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
                                    textScaleFactor: size,
                                    style: arabic,
                                    textDirection: TextDirection.rtl,
                                    locale: const Locale('ar'),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: FutureBuilder<List<Translation>>(
                                    future: loadTrans(),
                                    builder: (_, snapshot) {
                                      if (snapshot.hasData) {
                                        WidgetsBinding.instance!
                                            .addPostFrameCallback(
                                                (_) => scroll());

                                        var f = snapshot.data!;
                                        f.removeWhere(
                                            (v) => dis.contains(v.meta.key));

                                        return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: f.map((e) {
                                              List<InlineSpan> f = [];

                                              final t =
                                                  e.translations[p0.i - 1].text;

                                              int last = 0;

                                              RegExp(r'\<sup foot\_note\=\"?(\d*)\"?\>(\d*)\<\/sup\>')
                                                  .allMatches(t)
                                                  .forEach((element) {
                                                f.add(TextSpan(
                                                    text: t.substring(
                                                        last, element.start)));
                                                f.add(TextSpan(
                                                    text: element.group(2)!,
                                                    style: const TextStyle(
                                                        fontFeatures: [
                                                          FontFeature
                                                              .superscripts()
                                                        ],
                                                        color: Colors.green),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () => showDialog(
                                                          builder: (ctx) =>
                                                              Footnotes(
                                                                  fn: element
                                                                      .group(
                                                                          1)!),
                                                          context: context)));
                                                last = element.end;
                                              });

                                              f.add(TextSpan(
                                                  text: t.substring(last)));

                                              return Container(
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
                                                        Text.rich(TextSpan(
                                                            children: f)),
                                                        const Divider()
                                                      ]));
                                            }).toList());
                                      }
                                      return const CircularProgressIndicator();
                                    },
                                  ))
                            ]))),
                    const Divider()
                  ]);
                }).toList();

                List<Widget> k = [];

                if (widget.ind > 0) {
                  k.add(Flexible(child: ListTile(
                      title: Text(AppLocalizations.of(context)!.prev),
                      leading: const Icon(Icons.arrow_back),
                      subtitle: Text(prev,
                          style: ar ? arabic : null,
                          locale: ar ? const Locale('ar') : null,
                          textScaleFactor: ar ? 1.2 : null),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => ReadPage(
                                    surat: prev, ind: widget.ind - 1)));
                      })));
                }

                if (widget.ind < 113) {
                  k.add(Flexible(child: ListTile(
                      title: Text(AppLocalizations.of(context)!.next,
                          textAlign: TextAlign.end),
                      trailing: const Icon(Icons.arrow_forward),
                      subtitle: Text(next,
                          textAlign: TextAlign.end,
                          style: ar ? arabic : null,
                          locale: ar ? const Locale('ar') : null,
                          textScaleFactor: ar ? 1.2 : null),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => ReadPage(
                                    surat: next, ind: widget.ind + 1)));
                      })));
                }

                return ListView(
                    children: [...s, Row(children: k)], shrinkWrap: true);
              }

              return const Center(child: CircularProgressIndicator());
            },
          )
        ])));
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
