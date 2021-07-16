import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'footer.dart';
import 'menu_model.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MapSample();
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  // マップに関する設定
  Completer<GoogleMapController> _controller = Completer();
  Location _locationService = Location();

  // 現在位置
  LocationData? _yourLocation;

  // 現在位置の監視状況
  StreamSubscription? _locationChangedListen;

  // ズームの量
  double zoom = 18;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: ChangeNotifierProvider<MenuModel>(
            create: (_) => MenuModel(),
            child: Consumer<MenuModel>(builder: (context, model, child) {
              return Scaffold(
                body: _makeGoogleMap(model),
                floatingActionButton: Column(
                  verticalDirection:
                      VerticalDirection.up, // childrenの先頭が下に配置されます。
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // 1つ目のFAB
                    FloatingActionButton.extended(
                      heroTag: "goal",
                      icon: Icon(Icons.pin_drop_outlined),
                      label: Text('ゴール　'),
                      backgroundColor: Colors.blue[200],
                      onPressed: () async {
                        // （省略）タップされた際の処理
                      },
                    ),
                    // 2つ目のFAB
                    Container(
                      // 余白を設けるためContainerでラップします。
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: FloatingActionButton.extended(
                        // ユニークな名称をつけましょう。ないとエラーになります。
                        heroTag: "start",
                        icon: Icon(Icons.pin_drop_outlined),
                        label: Text('スタート'),
                        backgroundColor: Colors.pink[200],
                        onPressed: () async {
                          // 現在地をスタート地点としてマーカーを置く
                          model.createStartMarker(_yourLocation);
                        },
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Footer(),
              );
            })));
  }

  Widget _makeGoogleMap(model) {
    if (_yourLocation == null) {
      // 現在位置が取れるまではローディング中
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // Google Map ウィジェットを返す
      return GoogleMap(
        markers: model.markers,
        // 初期表示される位置情報を現在位置から設定
        initialCameraPosition: CameraPosition(
          target: LatLng(_yourLocation!.latitude as double,
              _yourLocation!.longitude as double),
          zoom: zoom,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        // 現在位置にアイコン（青い円形のやつ）を置く
        myLocationEnabled: true,
      );
    }
  }
}
