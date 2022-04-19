import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Info extends StatelessWidget {
  const Info({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.about)),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
                child: Wrap(
                    spacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                  const Image(
                      image: AssetImage("icon.png"), width: 140, height: 140),
                  Column(children: [
                    Text(AppLocalizations.of(context)!.quran,
                        style: Theme.of(context).textTheme.headlineMedium),
                    FutureBuilder<PackageInfo>(builder: (context, snapshot) {
                      if(snapshot.hasData) {
                        return Text(AppLocalizations.of(context)!.about2(snapshot.data!.version));
                      }

                      return const CircularProgressIndicator();
                    }, future: PackageInfo.fromPlatform())
                  ])
                ]))));
  }
}
