import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'footer.dart';

class MenuPage extends StatefulWidget {
  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  // マップに関する設定
  Completer<GoogleMapController> _controller = Completer();
  Location _locationService = Location();
  // 現在位置
  LocationData? _yourLocation;
  // 現在位置の監視状況
  StreamSubscription? _locationChangedListen;
  // マーカーの設定
  final Set<Marker> _markers = {};
  // Mapの表示設定
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();

    // 現在位置の取得
    _getLocation();

    // 現在位置の変化を監視
    _locationChangedListen =
        _locationService.onLocationChanged.listen((LocationData result) async {
      setState(() {
        _yourLocation = result;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    // 監視を終了
    _locationChangedListen?.cancel();
  }

  void _getLocation() async {
    _yourLocation = await _locationService.getLocation();
  }

  Widget _makeGoogleMap() {
    if (_yourLocation == null) {
      // 現在位置が取れるまではローディング中
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // Google Map ウィジェットを返す
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
            target: LatLng(_yourLocation!.latitude as double,
                _yourLocation!.longitude as double),
            zoom: 18),
        mapType: _currentMapType,
        markers: _markers,
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  // マーカーの数
  int markerNum = 0;
  // ダイアログのはい（1）・いいえ（0）の結果
  bool isAddStartMarker = false;
  // スタートを押した時の処理
  void _onAddStartMarkerButtonPressed() {
    String workTitle = '';
    String workContent = '';
    setState(() {
      if (markerNum == 0) {
        workTitle = '確認';
        workContent = '現在地をスタート地点としますか？';
        // マーカーを追加するかをユーザに聞き、「はい」であればマーカーを追加する
        _showDialog(context, workTitle, workContent, _addMarker,
            _addUserPositionToFirestore);
      } else {
        workTitle = '確認';
        workContent = 'スタート地点は既に設定されています。\n日本一周の記録を全て削除しますか？';
        // マーカーを削除するかをユーザに聞き、「はい」であればマーカーを削除する
        _showDialog(context, workTitle, workContent, _deleteMarker,
            _deleteUserPositionToFirestore);
      }
    });
  }

  bool isGoal = false;
  // ゴールを押した時の処理
  void _onAddGoalMarkerButtonPressed() {
    setState(() {
      if (markerNum == 0) {
        // 警告・スタート地点が設定されていません。スタートボタンを押して、スタート地点を設定してください。
        showDialog<void>(
          context: context,
          // 背景を押した時に、ダイアログは閉じない設定
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('警告'),
              content: Text('スタート地点が設定されていません。\nスタートボタンを押してください。'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        _showSimpleDialog(context);
        // showDialog 確認・markerNum日目の終了地点として設定しますか？ゴール地点として設定しますか？
        //                 1. markerNum日目の終了地点として設定
        //                    title: marker日目の終了地点 content: 最後まで諦めずに突き進みましょう！
        //                    上記の情報を持ったマーカーを追加する
        //                    データベースに位置情報を更新する
        //              if isGoal == false {
        //                 2. ゴール地点として設定
        //                    title: ゴール content: 最後までやりきったあなたは素晴らしいです！
        //                    上記の情報を持ったマーカーを追加する
        //                    データベースに位置情報を更新する
        //                    isGoalをtrueに変更する
        //              } else {
        //                    警告・ゴールは既に設定されています。 [OK]
        //                    スタートボタンでデータを消去した場合、isGoalを初期化（false）
        //                 3. 設定しない
        //                    Navigator.pop
      }
    });
  }

  Future<void> _showSimpleDialog(BuildContext context) async {
    String day = markerNum as String;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text('$day日目の終了地点として設定しますか？\nゴール地点として設定しますか？'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  // title: marker日目の終了地点 content: 最後まで諦めずに突き進みましょう！
                  // 上記の情報を持ったマーカーを追加する
                  _addMarker('$day日目の終了地点', '最後まで諦めずに突き進みましょう！');
                  // データベースに位置情報を更新する
                  _updateUserPositionToFirestore();
                  Navigator.pop(context);
                },
                child: Text('$day日目の終了地点として設定'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  // title: ゴール content: 最後までやりきったあなたは素晴らしいです！
                  // 上記の情報を持ったマーカーを追加する
                  Navigator.pop(context);
                },
                child: Text('ゴール地点として設定'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('設定しない'),
              ),
            ],
          );
        });
  }

  void _showDialog(BuildContext context, String title, String content,
      Function function, Function dbfunction) {
    showDialog<void>(
      context: context,
      // 背景を押した時に、ダイアログは閉じない設定
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text('はい'),
              onPressed: () {
                if (function == _addMarker) {
                  // マーカーを追加する
                  function('スタート地点', '本日の終了地点の設定をする場合は、「ゴール」ボタンを押してください。');
                  // Firestoreのデータベースにユーザーのスタート位置情報を追加する
                  dbfunction();
                } else {
                  // マーカーを削除する
                  function();
                  // Firestoreのデータベースのユーザ位置情報を全て削除する
                  dbfunction();
                }
                Navigator.of(context).pop(0);
              },
            ),
            FlatButton(
              child: Text('いいえ'),
              onPressed: () {
                Navigator.of(context).pop(1);
              },
            ),
          ],
        );
      },
    );
  }

  // マーカーを追加する処理
  void _addMarker(String title, String snippet) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_yourLocation.toString()),
          position: LatLng(_yourLocation!.latitude as double,
              _yourLocation!.longitude as double),
          infoWindow: InfoWindow(
            title: title,
            snippet: snippet,
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      markerNum++;
    });
  }

  // マーカーを削除する処理
  void _deleteMarker() {
    setState(() {
      // マーカーを全て削除する
      _markers.clear();
      // マーカーの数を初期化
      markerNum = 0;
    });
  }

  String documentId = '';
  // FireStoreにユーザ情報を追加する
  Future _addUserPositionToFirestore() async {
    final collection = FirebaseFirestore.instance.collection('userPosition');
    await collection.add({
      'email': _getUserEmail(),
      'geopoints': [
        GeoPoint(_yourLocation!.latitude as double,
            _yourLocation!.longitude as double)
      ],
    });
  }

  // FireStoreにユーザ情報の位置情報を更新する
  Future _updateUserPositionToFirestore() async {
    String email = _getUserEmail();
    final collection = FirebaseFirestore.instance.collection('userPosition');
    final snapshot = await collection.get();
    final docs = snapshot.docs;
    // それぞれのドキュメント
    docs.forEach((doc) {
      // アカウント設定した時のメールアドレスとドキュメント内のメールアドレスが一致している場合
      if (doc['email'] == email) {
        // そのドキュメントを更新する
        collection.doc(doc.id).update({
          'geopoints': FieldValue.arrayUnion([
            GeoPoint(_yourLocation!.latitude as double,
                _yourLocation!.longitude as double)
          ]),
        });
      }
    });
  }

  // FireStoreにユーザ位置情報を削除する
  Future _deleteUserPositionToFirestore() async {
    String email = _getUserEmail();
    final collection = FirebaseFirestore.instance.collection('userPosition');
    final snapshot = await collection.get();
    final docs = snapshot.docs;
    // それぞれのドキュメント
    docs.forEach((doc) {
      // アカウント設定した時のメールアドレスとドキュメント内のメールアドレスが一致している場合
      if (doc['email'] == email) {
        // そのドキュメントを削除する
        collection.doc(doc.id).delete();
      }
    });
  }

  // ユーザーのメールアドレスを取得する
  String _getUserEmail() {
    String userEmail = '';
    User? user = FirebaseAuth.instance.currentUser;
    userEmail = user!.email!;
    return userEmail;
  }

  Widget button(Function function, IconData icon, String label) {
    return FloatingActionButton.extended(
      onPressed: () {
        function();
      },
      materialTapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: Colors.blue,
      icon: Icon(
        icon,
        size: 36.0,
      ),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.withOpacity(0.7),
          title: Text('日本一周を記録しよう',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              )),
        ),
        body: Stack(
          children: <Widget>[
            _makeGoogleMap(),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    button(_onMapTypeButtonPressed, Icons.map, '地図切替'),
                    SizedBox(height: 16.0),
                    button(_onAddStartMarkerButtonPressed,
                        Icons.location_on_outlined, 'スタート'),
                    SizedBox(height: 16.0),
                    button(_onAddGoalMarkerButtonPressed, Icons.add_location,
                        'ゴール　'),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Footer(),
      ),
    );
  }
}
