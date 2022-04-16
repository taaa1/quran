import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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