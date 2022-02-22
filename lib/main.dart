import 'package:cbl/cbl.dart';
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:cbl_flutter_ce/cbl_flutter_ce.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Database? database;
  var replicator;

  Future<void> _incrementCounter() async {
    final doc = MutableDocument({
      'type': 'logMessage',
      'createdAt': DateTime.now(),
      'message': 'teste',
    });

    await database?.saveDocument(doc);

    // consultando dados no banco
    final query = const QueryBuilder()
        .select(
          SelectResult.expression(Meta.id),
          SelectResult.property('createdAt'),
          SelectResult.property('message'),
        )
        .from(DataSource.database(database!))
        .where(
          Expression.property('type').equalTo(Expression.value('logMessage')),
        )
        .orderBy(Ordering.property('createdAt'));

    // ResultSet resultSet = await query.execute();
    // var results = await resultSet.allResults();

    // for (var result in results) {
    //   print(result);
    // }

    ResultSet resultSet = await query.execute();
    var results = await resultSet.asStream().map((result) => result.toPlainMap()).toList();

    print(results[0]['id']);
    print(results[0]['createdAt']);
    print(results[0]['message']);

    await replicator.start();

    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      await CouchbaseLiteFlutter.init();
      database = await Database.openAsync('example.couchbase');

      // replicador
      replicator = await Replicator.create(
        ReplicatorConfiguration(
          database: database!,
          target: UrlEndpoint(Uri.parse('ws://localhost:4984/my-database')),
        ),
      );

      await replicator.addChangeListener((change) {
        debugPrint('Replicator activity: ${change.status.activity}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
