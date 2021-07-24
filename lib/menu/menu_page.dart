import 'dart:async';
import 'package:around_country/login/login_model.dart';
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
  // マーカーの数
  int markerNum = 0;
  // Mapの表示設定
  MapType _currentMapType = MapType.normal;
  // ゴール情報
  bool isGoal = false;

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

    // ユーザーの位置情報（マーカー）をセット
    _setMarker();
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
        // 現在位置にアイコン（青い円形のやつ）を置く
        myLocationEnabled: true,
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
        // ゴールしている場合
        if (isGoal == true) {
          // ゴール地点を既に設定していることをダイアログとして表示
          _okDialog(context, '警告', 'ゴール地点は既に設定されています。');
        } else {
          await _updateUserPositionToFirestore(false).then((result) {
            isSuccess = result;
          });
          if (isSuccess == true) {
            _addMarker1('$day日目の終了地点', '最後まで諦めずに突き進みましょう！');
          }
        }
        break;
      case Place.GoalPoint:
        bool isSuccess = false;
        // ゴールしている場合
        if (isGoal == true) {
          // ゴール地点を既に設定していることをダイアログとして表示
          _okDialog(context, '警告', 'ゴール地点は既に設定されています。');
        } else {
          await _updateUserPositionToFirestore(true).then((result) {
            isSuccess = result;
          });
          if (isSuccess == true) {
            _addMarker2('ゴール', '最後までやり切ったあなたは素敵です！\nお疲れ様でした！');
          }
        }
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

  // マーカーを追加する処理
  void _addMarker2(String title, String snippet) {
    setState(() {
      Marker marker = Marker(
        markerId: MarkerId(markerNum.toString()),
        position: LatLng(37.78794159304413, -122.40443928907779),
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
    final collection = FirebaseFirestore.instance.collection('users');
    collection.doc(LoginModel.userId).update({
      'geopoints': [
        GeoPoint(_yourLocation!.latitude as double,
            _yourLocation!.longitude as double)
      ],
    });
  }

  // FireStoreにユーザ情報の位置情報を更新する
  Future<bool> _updateUserPositionToFirestore(bool isGoalButtonPressed) async {
    final collection = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot docSnapshot =
        await collection.doc(LoginModel.userId).get();
    bool isSuccess = true;

    try {
      // データベースに格納された位置情報
      List<GeoPoint> geoPoints = List.from(docSnapshot['geopoints']);
      // 新しく追加する位置情報
      GeoPoint newGeoPoint = GeoPoint(37.78648424379196, -122.40495733028315);
      // データベースに格納された位置情報を要素毎に取り出す
      geoPoints.forEach((geoPoint) {
        // 新しく追加する位置情報とデータベースに格納されている位置情報が同じ地点を設定している場合
        if (geoPoint.latitude == newGeoPoint.latitude &&
            geoPoint.longitude == newGeoPoint.longitude) {
          // データベースに位置情報を追加することができないため、エラーを出力する
          isSuccess = false;
        }
      });
      if (isSuccess == true) {
        // 位置情報を追加する
        collection.doc(LoginModel.userId).update({
          'geopoints': FieldValue.arrayUnion([newGeoPoint]),
        });
        // ゴールとして設定する場合
        if (isGoalButtonPressed == true) {
          // ゴールした情報を更新する
          collection.doc(LoginModel.userId).update({
            'isGoal': true,
          });
          // ゴールした
          isGoal = true;
        }
      } else {
        throw ('同じ地点を設定することができません。');
      }
    } catch (e) {
      _okDialog(context, 'エラー', e.toString());
    }
    return isSuccess;
  }

  // FireStoreにユーザ位置情報を削除する
  Future _deleteUserPositionToFirestore() async {
    final collection = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot docSnapshot =
        await collection.doc(LoginModel.userId).get();
    // 位置情報を空にする
    collection.doc(LoginModel.userId).update({
      'geopoints': {},
    });
    // ゴールしている場合
    if (isGoal == true) {
      isGoal = false;
    }
  }

  // ユーザーのメールアドレスを取得する
  String _getUserEmail() {
    String userEmail = '';
    User? user = FirebaseAuth.instance.currentUser;
    userEmail = user!.email!;
    return userEmail;
  }

  // データベースにユーザの位置情報がある場合、マーカーをセットしていく
  Future<void> _setMarker() async {
    String email = _getUserEmail();
    final collection = FirebaseFirestore.instance.collection('userPosition');
    final snapshot = await collection.get();
    final docs = snapshot.docs;
    bool isSuccess = true;
    int day = 1;

    // それぞれのドキュメント
    docs.forEach((doc) {
      // アカウント設定した時のメールアドレスとドキュメント内のメールアドレスが一致している場合
      if (doc['email'] == email) {
        // データベースに格納された位置情報
        List<GeoPoint> geoPoints = List.from(doc['geopoints']);
        // ゴールしているか確認できる変数
        bool isGoalFirebase = doc['isGoal'];
        geoPoints.forEach((geoPoint) {
          double latitude = geoPoint.latitude;
          double longitude = geoPoint.longitude;
          if (markerNum == 0) {
            _setAddMarker('スタート地点', '本日の終了地点の設定をする場合は、「ゴール」ボタンを押してください。',
                latitude, longitude);
          } else if (markerNum == (docs.length - 1)) {
            if (isGoalFirebase == true) {
              _setAddMarker(
                  'ゴール', '最後までやり切ったあなたは素敵です！\nお疲れ様でした！', latitude, longitude);
              isGoal = true;
            } else {
              _setAddMarker(
                  '$day日目の終了地点', '最後まで諦めずに突き進みましょう！', latitude, longitude);
              day++;
            }
          } else {
            _setAddMarker(
                '$day日目の終了地点', '最後まで諦めずに突き進みましょう！', latitude, longitude);
            day++;
          }
        });
      }
    });
  }

  // マーカーを設定していく処理
  void _setAddMarker(String title, String snippet, latitude, longitude) {
    Marker marker = Marker(
      markerId: MarkerId(markerNum.toString()),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    _markers.add(marker);
    markerNum++;
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
