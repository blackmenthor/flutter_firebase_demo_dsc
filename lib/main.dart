import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const SHOW_BTN_KEY = 'show_button';

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  RemoteConfig _remoteConfig;
  Timer _timer;

  var _showBtn = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setupRemoteConfig();
    });
  }

  void setupRemoteConfig() async {
    _remoteConfig = RemoteConfig.instance;
    // Allow a fetch every millisecond. Default is 12 hours.
    _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        minimumFetchInterval: Duration(seconds: 1),
        fetchTimeout: Duration(minutes: 5),
      ),
    );
    _remoteConfig.setDefaults(<String, dynamic>{
      SHOW_BTN_KEY: 1,
    });

    await _remoteConfig.fetch();
    await _remoteConfig.fetchAndActivate();
    _showBtn = (_remoteConfig?.getInt(SHOW_BTN_KEY) ?? 1) == 1;

    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _remoteConfig.fetch();
      await _remoteConfig.fetchAndActivate();
      _showBtn = (_remoteConfig?.getInt(SHOW_BTN_KEY) ?? 1) == 1;

      setState(() {});
    });

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
    _remoteConfig?.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, stream) {
          if (stream.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stream.hasError) {
            return Center(child: Text(stream.error.toString()));
          }

          QuerySnapshot querySnapshot = stream.data;

          return ListView.builder(
            itemCount: querySnapshot.size,
            itemBuilder: (context, index) => UserWidget(
              name: querySnapshot.docs[index]['name'],
              phone: querySnapshot.docs[index]['phone'],
              key: ValueKey(querySnapshot.docs[index].id),
            ),
          );
        },
      ),
      floatingActionButton: _showBtn
          ? FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: Icon(Icons.add),
            )
          : Container(),
    );
  }
}

class UserWidget extends StatelessWidget {
  final String name;
  final String phone;

  UserWidget({
    @required this.name,
    @required this.phone,
    ValueKey key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
          Text(
            phone,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
