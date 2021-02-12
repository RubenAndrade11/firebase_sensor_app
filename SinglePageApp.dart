import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_sensor/DHT.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

class SinglePageApp extends StatefulWidget {
  @override
  _SinglePageAppState createState() => _SinglePageAppState();
}

class _SinglePageAppState extends State<SinglePageApp>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  int tabIndex = 0;

  bool _signIn;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  DatabaseReference _dhtRef = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    _signIn = false;
    _tabController = TabController(length: 2, vsync: this);
    googleSignIn.signInSilently();
    print('lol1');
  }

  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> signInWithGoogle() async {
    await Firebase.initializeApp();

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user;

    if (user != null) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final User currentUser = _auth.currentUser;
      assert(user.uid == currentUser.uid);

      print('signInWithGoogle succeeded: $user');

      return '$user';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _signIn ? mainScaffold() : signInScaffold();
  }

  Widget mainScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signIn ? 'True' : 'False'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (int index) {
            setState(() {
              tabIndex = index;
            });
          },
          tabs: [
            Tab(
              icon: Icon(Icons.ac_unit),
            ),
            Tab(
              icon: Icon(Icons.ac_unit),
            )
          ],
        ),
      ),
      body: StreamBuilder(
          stream: _dhtRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                !snapshot.hasError &&
                snapshot.data.snapshot.value != null) {
              print(
                  'snapshot data: ${snapshot.data.snapshot.value.toString()}');
              var _dht = DHT.fromJson(snapshot.data.snapshot.value);
              print('DHT: ${_dht.temp} / ${_dht.humidity}');

              return IndexedStack(
                index: tabIndex,
                children: [_temperatureLayout(_dht), _humidityLayout(_dht)],
              );
            } else {
              return Center(
                child: Text('NO DATA YET'),
              );
            }
          }),
    );
  }

  Widget _temperatureLayout(DHT _dht) {
    return Center(
        child: Column(
        children: [
          Container(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'Nível de gás',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: FAProgressBar(
                progressColor: Colors.red,
                direction: Axis.vertical,
                verticalDirection: VerticalDirection.up,
                size: 100,
                currentValue: _dht.temp.round(),
                changeColorValue: 20,
                changeProgressColor: Colors.green,
                maxValue: 100,
                displayText: '%',
                borderRadius: 16,
               animatedDuration: Duration(milliseconds: 500),
             ),
           ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 40),
            child: Text(
            ' ${_dht.temp.round().toStringAsFixed(2)} %',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          )
        ],
     ));
  }

  Widget _humidityLayout(DHT _dht) {
    return Center(
      child: Text('Humidity'),
    );
  }

  Widget signInScaffold() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FEBsecure',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(
              height: 50,
            ),
            RaisedButton(
              textColor: Colors.white,
              color: Colors.red,
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red)),
              onPressed: () async {
                signInWithGoogle().then((result) {
                  if (result != null) {
                    print('lol');
                    setState(() {
                      _signIn = true;
                    });
                  }
                });
              },
              child: Text(
                'Google Sign-In',
                style: TextStyle(fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}
