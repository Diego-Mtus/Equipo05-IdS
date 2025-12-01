import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objetos_perdidos/coincidencia.dart';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';
import 'package:objetos_perdidos/detalle_reporte.dart';
import 'package:objetos_perdidos/image_store.dart';

class DetalleCoincidenciaScreen extends StatefulWidget {
  final Coincidencia coincidencia;
  const DetalleCoincidenciaScreen({Key? key, required this.coincidencia}) : super(key: key);

  @override
  State<DetalleCoincidenciaScreen> createState() => _DetalleCoincidenciaScreenState();
}

class _DetalleCoincidenciaScreenState extends State<DetalleCoincidenciaScreen> {
  bool _processing = false;

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatFecha(DateTime d) {
    final dt = d.toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _estadoTexto(EstadoCoincidencia e) {
    switch (e) {
      case EstadoCoincidencia.PENDIENTE:
        return 'Pendiente';
      case EstadoCoincidencia.CONFIRMADA_POR_ADMIN:
        return 'Confirmado por administrador';
      case EstadoCoincidencia.RESUELTA:
        return 'Resuelta';
    }
  }

  Future<void> _cambiarEstado(EstadoCoincidencia nuevoEstado) async {
    setState(() => _processing = true);
    try {
      final updated = Coincidencia(
        reportePerdido: widget.coincidencia.reportePerdido,
        reporteEncontrado: widget.coincidencia.reporteEncontrado,
        peso: widget.coincidencia.peso,
        fechaDeteccion: widget.coincidencia.fechaDeteccion,
        estado: nuevoEstado,
      );
      await actualizarCoincidenciaLocal(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coincidencia actualizada: ${_estadoTexto(nuevoEstado)}')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error actualizando: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _eliminarCoincidencia() async {
    setState(() => _processing = true);
    try {
      await eliminarCoincidenciaLocal(widget.coincidencia.idUnico);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coincidencia eliminada')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool> _confirmDialog(String title, String message, String confirmLabel) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(confirmLabel)),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coincidencia;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de coincidencia', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coincidencia: ${(c.peso * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Detectada: ${_formatFecha(c.fechaDeteccion)}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text('Estado: ${_estadoTexto(c.estado)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Reporte perdido
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: const Text('Reporte perdido', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_capitalize(c.reportePerdido.descripcion)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetalleReporteScreen(reporte: c.reportePerdido, backEnable: true)),
                    );
                  },
                  child: const Text('Ver'),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Reporte encontrado
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: const Text('Reporte encontrado', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_capitalize(c.reporteEncontrado.descripcion)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetalleReporteScreen(reporte: c.reporteEncontrado, backEnable: true)),
                    );
                  },
                  child: const Text('Ver'),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Imagenes rápidas (si existen)
            if (_hasImage(c.reportePerdido)) ...[
              const Text('Imagen - Reporte perdido', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildMiniImage(context, c.reportePerdido.imagenPath!),
              const SizedBox(height: 12),
            ],

            if (_hasImage(c.reporteEncontrado)) ...[
              const Text('Imagen - Reporte encontrado', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildMiniImage(context, c.reporteEncontrado.imagenPath!),
            ],

            const SizedBox(height: 18),

            // Acciones
            if (_processing)
              const Center(child: CircularProgressIndicator())
            else if (c.estado == EstadoCoincidencia.CONFIRMADA_POR_ADMIN)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: const Text('Marcar como resuelta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final ok = await _confirmDialog('Marcar como resuelta', '¿Deseas marcar esta coincidencia como resuelta? Esta acción la marcará como resuelta.', 'Marcar como resuelta');
                        if (ok) await _cambiarEstado(EstadoCoincidencia.RESUELTA);
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final ok = await _confirmDialog('Confirmar coincidencia', '¿Deseas confirmar esta coincidencia? Esta acción marcará la coincidencia como confirmada por el administrador.', 'Confirmar');
                        if (ok) await _cambiarEstado(EstadoCoincidencia.CONFIRMADA_POR_ADMIN);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final ok = await _confirmDialog('Eliminar coincidencia', '¿Deseas eliminar esta coincidencia? Esta acción no se puede deshacer.', 'Eliminar');
                        if (ok) await _eliminarCoincidencia();
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _hasImage(dynamic reporte) {
    final String? path = reporte.imagenPath;
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('hive:')) {
      final id = path.substring(5);
      return ImageStore.hasImageSync(id);
    }
    return kIsWeb || File(path).existsSync();
  }

  Widget _buildMiniImage(BuildContext context, String path) {
    Widget img;
    if (path.startsWith('hive:')) {
      final id = path.substring(5);
      final bytes = ImageStore.loadReportImageSync(id);
      if (bytes != null) {
        img = Image.memory(bytes, height: 160, width: double.infinity, fit: BoxFit.cover);
      } else {
        img = Container(height: 160, color: Colors.grey[200], alignment: Alignment.center, child: const Text('Imagen no disponible'));
      }
    } else {
      img = kIsWeb
          ? Image.network(path, height: 160, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(path), height: 160, width: double.infinity, fit: BoxFit.cover);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(12), child: GestureDetector(onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImageScreen(imagePath: path)));
    }, child: img));
  }
}
