import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xml/xml.dart';

import 'package:flutter/services.dart' show rootBundle;

XmlDocument? document;

void main() {
  runApp(const MyApp());
  rootBundle.loadString('assets/quran.xml').then((value) {
    document = XmlDocument.parse(value);
  });
}

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
        ),
        body: SingleChildScrollView(child: Container(
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
                      List<Widget> a = XmlDocument.parse(snapshot.data!)
                          .getElement("quran")!
                          .childElements
                          .map((p0) => Card(
                              child: InkWell(
                                  splashColor: Colors.green,
                                  onTap: () {
                                    debugPrint("a");
                                  },
                                  child: ListTile(
                                      title: Text(p0.getAttribute("name")!)))))
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
