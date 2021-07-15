import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MenuModel extends GetxController {
  Set<Marker> markers = {};
  int _markerId = 1;

  void createStartMarker(yourLocation) {
    if (_markerId == 1) {
      markers.add(Marker(
        markerId: MarkerId(_markerId as String),
        position: LatLng(yourLocation!.latitude as double,
            yourLocation!.longitude as double),
      ));
      _markerId++;
    }
  }
}
