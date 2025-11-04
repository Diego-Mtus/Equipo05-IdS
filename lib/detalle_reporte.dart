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
      appBar: AppBar(title: const Text('Detalle del reporte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Descripción: ${reporte.descripcion}'),
            Text('Ubicación: ${reporte.ubicacion}'),
            Text(
              'Fecha: ${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year}',
            ),
            Text('Tipo: ${reporte.tipo.name}'),
            const SizedBox(height: 16),
            if (reporte.tags.isNotEmpty) ...[
              const Text('Tags:'),
              Wrap(
                spacing: 6,
                children: reporte.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (reporte.imagenPath != null)
              (kIsWeb
                  ? Image.network(reporte.imagenPath!, height: 200)
                  : Image.file(File(reporte.imagenPath!), height: 200))
            else
              const Text('Sin imagen adjunta'),
            const Divider(height: 32),
            Text(
              'Datos del usuario',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (reporte.usuario != null) ...[
              Text('Nombre: ${reporte.usuario!.nombre}'),
              Text('Correo: ${reporte.usuario!.correo}'),
              Text('Matrícula: ${reporte.usuario!.nMatricula}'),
            ] else
              const Text('Sin información del usuario.'),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // Cierra todas las pantallas y vuelve a la raíz
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
