import 'dart:convert';

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

  // Aqui recebemos as variáveis que virão do ambiente via dart-define
  static const String constCouchGwUser = String.fromEnvironment('couchGwUser');
  static const String constCouchGwPwd = String.fromEnvironment('couchGwPwd');
  static const String constEndPointUrl = String.fromEnvironment('endPointUrl');

  // Aqui decodificamos de base64 para o valor original
  String couchGwUser = Utf8Codec().decode(base64Decode(constCouchGwUser));
  String couchGwPwd = Utf8Codec().decode(base64Decode(constCouchGwPwd));
  String endPointUrl = Utf8Codec().decode(base64Decode(constEndPointUrl));

  Future<void> _incrementCounter() async {
    await replicator.start();

    final doc = MutableDocument({
      'type': 'logMessage',
      'createdAt': DateTime.now(),
      'message': 'teste',
      'channels': ['userA'] // canal que esse documento será atribuido
    });

    await database?.saveDocument(doc);

    // consultando dados no banco
    final query = const QueryBuilder()
        .select(
          SelectResult.expression(Meta.id),
          SelectResult.property('createdAt'),
          SelectResult.property('message'),
          SelectResult.property('type'),
        )
        .from(DataSource.database(database!))
        // .where(
        //   Expression.property('type').equalTo(Expression.value('logMessage')),
        // )
        .orderBy(Ordering.property('createdAt'));

    // ResultSet resultSet = await query.execute();
    // var results = await resultSet.allResults();

    // for (var result in results) {
    //   print(result);
    // }

    ResultSet resultSet = await query.execute();
    var results = await resultSet.asStream().map((result) => result.toPlainMap()).toList();

    for (var result in results) {
      print(result);
    }

    // print(results[0]['id']);
    // print(results[0]['type']);
    // print(results[0]['createdAt']);
    // print(results[0]['message']);

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

      database = await Database.openAsync('example-database6');

      // replicador
      replicator = await Replicator.create(
        ReplicatorConfiguration(
          database: database!,
          target: UrlEndpoint(Uri.parse(endPointUrl)),
          channels: ['userA'],
          // authenticador
          authenticator: BasicAuthenticator(username: couchGwUser, password: couchGwPwd),
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
