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
  Set<Marker> _markers = {};
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
        // markers: _markers.map((e) => e).toSet(),
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
        _showSimpleDialog();
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

  Future<void> _showSimpleDialog() async {
    String day = markerNum.toString();
    switch (await showDialog(
      context: context,
      // barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('選択してください'),
          children: [
            SimpleDialogOption(
              child: Text('$day日目の終了地点として設定'),
              onPressed: () {
                Navigator.pop(context, Place.HalfwayPoint);
              },
            ),
            SimpleDialogOption(
              child: Text('ゴール地点として設定'),
              onPressed: () {
                Navigator.pop(context, Place.GoalPoint);
              },
            ),
            SimpleDialogOption(
              child: Text('設定しない'),
              onPressed: () {
                Navigator.pop(context, Place.Nothing);
              },
            ),
          ],
        );
      },
    )) {
      case Place.HalfwayPoint:
        bool isSuccess = false;
        await _updateUserPositionToFirestore().then((result) {
          isSuccess = result;
        });
        if (isSuccess == true) {
          _addMarker1('$day日目の終了地点', '最後まで諦めずに突き進みましょう！');
        }
        break;
      case Place.GoalPoint:
        break;
      case Place.Nothing:
        break;
      case null:
        break;
    }
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
                  // Firestoreのデータベースにユーザーのスタート位置情報を追加する
                  dbfunction();
                  // マーカーを追加する
                  function('スタート地点', '本日の終了地点の設定をする場合は、「ゴール」ボタンを押してください。');
                } else {
                  // Firestoreのデータベースのユーザ位置情報を全て削除する
                  dbfunction();
                  // マーカーを削除する
                  function();
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

  Future<void> _okDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
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
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
      Marker marker = Marker(
        markerId: MarkerId(markerNum.toString()),
        position: LatLng(_yourLocation!.latitude as double,
            _yourLocation!.longitude as double),
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      _markers.add(marker);
      markerNum++;
    });
  }

  // マーカーを追加する処理
  void _addMarker1(String title, String snippet) {
    setState(() {
      Marker marker = Marker(
        markerId: MarkerId(markerNum.toString()),
        position: LatLng(37.78648424379196, -122.40495733028315),
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      _markers.add(marker);
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
  Future<bool> _updateUserPositionToFirestore() async {
    String email = _getUserEmail();
    final collection = FirebaseFirestore.instance.collection('userPosition');
    final snapshot = await collection.get();
    final docs = snapshot.docs;
    bool isSuccess = true;

    try {
      // それぞれのドキュメント
      docs.forEach((doc) {
        // アカウント設定した時のメールアドレスとドキュメント内のメールアドレスが一致している場合
        if (doc['email'] == email) {
          // データベースに格納された位置情報
          List<GeoPoint> geoPoints = List.from(doc['geopoints']);
          // 新しく追加する位置情報
          GeoPoint newGeoPoint = GeoPoint(_yourLocation!.latitude as double,
              _yourLocation!.longitude as double);
          // データベースに格納された位置情報を要素毎に取り出す
          geoPoints.forEach((geoPoint) {
            // 新しく追加する位置情報とデータベースに格納されている位置情報が同じ地点を設定している場合
            if (geoPoint.latitude == newGeoPoint.latitude &&
                geoPoint.longitude == newGeoPoint.longitude) {
              // データベースに位置情報を追加することができないため、エラーを出力する
              isSuccess = false;
              throw ('同じ地点を設定することができません。');
            } else {
              // そのドキュメントを更新する
              collection.doc(doc.id).update({
                'geopoints': FieldValue.arrayUnion([newGeoPoint]),
              });
            }
          });
        }
      });
    } catch (e) {
      _okDialog(context, 'エラー', e.toString());
    }
    return isSuccess;
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

enum Place { GoalPoint, HalfwayPoint, Nothing }
