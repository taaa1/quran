import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Info extends StatelessWidget {
  const Info({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.about)),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
                child: Column(children: [
              const Image(
                  image: AssetImage("icon.png"), width: 140, height: 140),
              Text(AppLocalizations.of(context)!.quran, style: Theme.of(context).textTheme.headlineMedium),
              Text(AppLocalizations.of(context)!.about2)
            ]))));
  }
}
