import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class Fn extends StatelessWidget {
  const Fn({Key? key, required this.fn}) : super(key: key);

  final String fn;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.footnote),
      content: SingleChildScrollView(
          child: SizedBox(
              width: 400,
              child: FutureBuilder<http.Response>(
                  future: http.get(
                      Uri.parse("https://api.quran.com/api/v4/foot_notes/$fn")),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(AppLocalizations.of(context)!.footnoteErr);
                    }

                    if (snapshot.hasData) {
                      if (snapshot.data!.statusCode != 200) {
                        return Text(AppLocalizations.of(context)!.footnoteErr);
                      }

                      return SelectableText(
                          jsonDecode(snapshot.data!.body)['foot_note']['text']);
                    }

                    return const Center(child: CircularProgressIndicator());
                  }))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok))
      ],
    );
  }
}
