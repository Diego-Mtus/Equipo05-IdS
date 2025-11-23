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
    const LatLng(-36.8360, -73.0402),
    const LatLng(-36.8247, -73.0310),
  );

  final MapController _mapController = MapController();

  LatLng? _posicionActual;
  bool _mostrarInfo = true;

  @override
  void initState() {
    super.initState();
    _posicionActual = widget.ubicacionInicial ?? _centroUdec;
  }

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
      appBar: AppBar(
        title: const Text(
          "Selecciona la ubicación",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ====== MAPA ======
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _posicionActual!,
                initialZoom: 16.0,
                minZoom: 15.0,
                maxZoom: 20,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: _limitesUdec,
                ),
                interactiveFlags: InteractiveFlag.all,
                onMapEvent: _actualizarPosicionPin,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.udec.objetos_perdidos',
                ),
              ],
            ),
          ),

          // ====== PIN CENTRADO ======
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.red[700],
                  size: 48,
                ),
                const SizedBox(height: 5),
                Container(
                  height: 6,
                  width: 6,
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // ====== CARD DE INFORMACIÓN======
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _mostrarInfo ? 1 : 0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              child: _mostrarInfo
                  ? GestureDetector(
                      onTap: () {
                        setState(() => _mostrarInfo = false);
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Mueve el mapa para ubicar el pin.\n"
                                  "Solo se permiten posiciones dentro del campus UdeC.",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // ====== BOTÓN CONFIRMAR ======
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 5,
                ),
                onPressed: () => Navigator.of(context).pop(_posicionActual),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 22,
                  color: Colors.white,
                ),
                label: const Text(
                  "Confirmar ubicación",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
