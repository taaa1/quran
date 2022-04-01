import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xml/xml.dart';

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
                          List<Widget> a = k.toList().asMap().entries.map((p0) => Card(
                                  child: InkWell(
                                      splashColor: Colors.green,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ReadPage(
                                                      surat: p0.value.getAttribute(
                                                          "name")!,
                                                      ind: p0.key
                                                    )));
                                      },
                                      child: ListTile(
                                          title:
                                              Text(p0.value.getAttribute("name")!, style: arabic, textScaleFactor: 1.5, textAlign: TextAlign.right)))))
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
  const ReadPage({Key? key, required this.surat, required this.ind}) : super(key: key);

  final String surat;
  final int ind;

  @override
  State<ReadPage> createState() => _ReadPageS();
}

class _ReadPageS extends State<ReadPage> {
  late Future<String> _data;

  @override void initState() {
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
            if(snapshot.hasData) {
              List<Widget> s = XmlDocument.parse(snapshot.data.toString()).getElement("quran")!.childElements.elementAt(widget.ind).childElements
              .map((p0) => Column(children: [Container(padding: const EdgeInsets.all(8),child: ListTile(title: Text(p0.getAttribute("text")!, textScaleFactor: 2, style: arabic, textDirection: TextDirection.rtl,))), const Divider()]))
              .toList();
              return ListView(children: s, shrinkWrap: true);
            }

            return const Center(child: CircularProgressIndicator());
          },
        )
      )
    );
  }
}
