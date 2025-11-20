import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectorMapaUdec extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SelectorMapaUdec({super.key, this.ubicacionInicial});

  @override
  State<SelectorMapaUdec> createState() => _SelectorMapaUdecState();
}

class _SelectorMapaUdecState extends State<SelectorMapaUdec> {
  final LatLng _centroUdec = const LatLng(-36.8296, -73.0360);
  final LatLngBounds _limitesUdec = LatLngBounds(
    const LatLng(-36.8360, -73.0420),
    const LatLng(-36.8200, -73.0280),
  );

  final MapController _mapController = MapController();

  LatLng? _posicionActual;

  @override
  void initState() {
    super.initState();

    _posicionActual = widget.ubicacionInicial ?? _centroUdec;
  }

  // 3. Función para actualizar la posición solo cuando el mapa se detiene
  void _actualizarPosicionPin(MapEvent mapEvent) {
    if (mapEvent is MapEventMoveEnd) {
      setState(() {
        _posicionActual = _mapController.camera.center;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mueve el mapa para ubicar el pin")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _posicionActual!,
              initialZoom: 16.0,
              minZoom: 15.0,
              interactiveFlags: InteractiveFlag.all,
              cameraConstraint: CameraConstraint.contain(bounds: _limitesUdec),

              onMapEvent: _actualizarPosicionPin,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.udec.objetos_perdidos',
              ),
            ],
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Icon(Icons.location_on, color: Colors.red[700], size: 45),
            ),
          ),

          if (_posicionActual != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  // Devolvemos la posición central del mapa
                  Navigator.of(context).pop(_posicionActual);
                },
                child: const Text(
                  "Confirmar Ubicación",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
