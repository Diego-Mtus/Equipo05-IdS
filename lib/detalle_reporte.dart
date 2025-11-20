import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/reporte.dart';

class DetalleReporteScreen extends StatelessWidget {
  final Reporte reporte;
  const DetalleReporteScreen({super.key, required this.reporte});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del reporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== Imagen ======
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: reporte.imagenPath != null
                  ? (kIsWeb
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
                          ))
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Text(
                        'Sin imagen adjunta',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
            ),

            const SizedBox(height: 25),

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

                    _infoRow("Descripción", reporte.descripcion),
                    const SizedBox(height: 10),

                    _infoRow("Ubicación", reporte.ubicacion),
                    const SizedBox(height: 10),

                    _infoRow(
                      "Fecha",
                      "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year}",
                    ),
                    const SizedBox(height: 10),

                    _infoRow("Tipo", reporte.tipo.name),

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

            const SizedBox(height: 25),

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
                      _infoRow("Correo", reporte.usuario!.correo),
                      const SizedBox(height: 10),
                      _infoRow("Matrícula", reporte.usuario!.nMatricula),
                    ] else
                      const Text("Sin información del usuario."),
                  ],
                ),
              ),
            ),

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
        ),
      ),
    );
  }

  // ====== Widget para los conjuntos ======
  Widget _infoRow(String title, String value) {
    return Column(
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
    );
  }
}
