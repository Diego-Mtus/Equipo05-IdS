import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/image_store.dart';

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class DetalleReporteScreen extends StatelessWidget {
  final Reporte reporte;
  final bool backEnable;
  const DetalleReporteScreen({super.key, required this.reporte, required this.backEnable});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del reporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: backEnable,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== Imagen ======
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  if (reporte.imagenPath == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullscreenImageScreen(imagePath: reporte.imagenPath!),
                    ),
                  );
                },
                child: (() {
                  if (reporte.imagenPath == null){
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Text(
                        'Sin imagen adjunta',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  // Hive stored image
                  if (reporte.imagenPath!.startsWith('hive:')) {
                    final id = reporte.imagenPath!.substring(5);
                    final Uint8List? bytes = ImageStore.loadReportImageSync(id);
                    if (bytes != null) {
                      return Image.memory(
                        bytes,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    } else {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Text('Imagen no disponible'),
                      );
                    }
                  }

                  // Legacy: local file or network
                  return kIsWeb
                      ? Image.network(
                          reporte.imagenPath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(reporte.imagenPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                })(),
              ),
            ),

            const SizedBox(height: 24),

            // ====== Datos del Reporte ======
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información del objeto",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoRow("Descripción", _capitalize(reporte.descripcion)),
                    const SizedBox(height: 10),

                    _infoRow(
                      "Fecha",
                      "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year}",
                    ),
                    const SizedBox(height: 10),

                    _infoRow("Tipo", reporte.tipo.name[0].toUpperCase() + reporte.tipo.name.substring(1)),

                    const SizedBox(height: 16),

                    if (reporte.tags.isNotEmpty) ...[
                      const Text(
                        "Tags",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: reporte.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.blue.shade50,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===== Ubicación del reporte =====
            const Text(
              "Ubicación del reporte",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 260,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: reporte.coordenadas!,
                      initialZoom: 17,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.udec.objetos_perdidos',
                      ),

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: reporte.coordenadas!,
                            width: 50,
                            height: 50,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.red[700],
                                  size: 42,
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ====== Datos del Usuario ======
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Datos del usuario",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (reporte.usuario != null) ...[
                      _infoRow("Nombre", reporte.usuario!.nombre),
                      const SizedBox(height: 10),
                      _infoRow("Correo", reporte.usuario!.correo, context),
                      const SizedBox(height: 10),
                      _infoRow("Teléfono", reporte.usuario!.telefono, context),
                    ] else
                      const Text("Sin información del usuario."),
                  ],
                ),
              ),
            ),
            if(!backEnable) ...[
              const SizedBox(height: 40),
            // ===== Botón Volver =====
            
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text(
                    "Volver al inicio",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copiarAlPortapapeles(BuildContext context, String texto) async {
    try {
      await Clipboard.setData(ClipboardData(text: texto));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al copiar: $e')));
    }
  }

  Widget _infoRow(String title, String value, [BuildContext? context]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
        if (context != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copiar $title',
            onPressed: () => _copiarAlPortapapeles(context, value),
          ),
      ],
    );
  }

}

class FullscreenImageScreen extends StatelessWidget {
  final String imagePath;

  const FullscreenImageScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imagePath.startsWith('hive:')) {
      final id = imagePath.substring(5);
      final bytes = ImageStore.loadReportImageSync(id);
      if (bytes != null) {
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } else {
        imageWidget = const SizedBox.shrink();
      }
    } else {
      imageWidget = kIsWeb
          ? Image.network(imagePath, fit: BoxFit.contain)
          : Image.file(File(imagePath), fit: BoxFit.contain);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          minScale: 0.5,
          child: imageWidget,
        ),
      ),
    );
  }
}
