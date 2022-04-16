import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'd/quran.dart';

class Footnotes extends StatefulWidget {
  const Footnotes({Key? key, required this.fn}) : super(key: key);

  final String fn;

  @override
  State<Footnotes> createState() => Fn();
}

class Fn extends State<Footnotes> {
  String? open;
  bool err = false;

  @override
  void initState() {
    super.initState();

    http
        .get(Uri.parse(
            "https://api.qurancdn.com/api/qdc/foot_notes/${widget.fn}"))
        .then((v) {
      if (v.statusCode == 200) {
        setState(() => open = v.body);
      } else {
        setState(() => err = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.footnote),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: err
          ? Text(AppLocalizations.of(context)!.footnoteErr)
          : open != null
              ? Text(jsonDecode(open!)['foot_note']['text'])
              : const Center(child: CircularProgressIndicator()))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok))
      ],
    );
  }
}
