import 'dart:async';
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

  // 設置する予定のマーカーの数
  int markerNum = 1;
  // ダイアログのはい（1）・いいえ（0）の結果
  bool isAddStartMarker = false;
  _onAddStartMarkerButtonPressed() {
    setState(() {
      if (markerNum == 1) {
        isAddStartMarker = _showDialog(context, '確認', '現在地をスタート地点としますか？');
        if (isAddStartMarker == true) {
          _markers.add(
            Marker(
              markerId: MarkerId(_yourLocation.toString()),
              position: LatLng(_yourLocation!.latitude as double,
                  _yourLocation!.longitude as double),
              infoWindow: InfoWindow(
                title: 'スタート地点',
                snippet: '日本一周を達成しましょう！',
              ),
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          markerNum++;
        }
      }
    });
  }

  bool _showDialog(BuildContext context, String title, String content) {
    bool result = false;
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
                Navigator.of(context).pop(0);
                result = true;
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
    return result;
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
                    button(_onAddStartMarkerButtonPressed, Icons.add_location,
                        'スタート'),
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
