import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/detalle_reporte.dart';
import 'package:objetos_perdidos/coincidencia.dart';
import 'package:objetos_perdidos/algoritmo_coincidencias.dart';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportesWidget extends StatefulWidget {
  const ReportesWidget({Key? key}) : super(key: key);

  @override
  State<ReportesWidget> createState() => _ReportesWidgetState();
}

class _ReportesWidgetState extends State<ReportesWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Reporte> _reportes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    setState(() => _loading = true);

    try {
      List<Reporte> lista = await obtenerReportesLocales();

      setState(() {
        _reportes = lista;
        _loading = false;
      });

      print('Reportes cargados: ${_reportes.length}');
    } catch (e, st) {
      print('Error general en _loadReportes: $e\n$st');
      setState(() {
        _reportes = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leyendo reportes: $e')));
      }
    }
  }

  bool _esPerdido(Reporte r) => r.tipo == TipoObjeto.perdido;
  bool _esEncontrado(Reporte r) => r.tipo == TipoObjeto.encontrado;

  Widget _buildListTile(Reporte r) {
    // Evitar el uso de APIs relacionadas con archivos en web
    final bool hasImage = (() {
      if (r.imagenPath == null || r.imagenPath!.isEmpty) return false;
      if (kIsWeb) {
        return true;
      } else {
        try {
          return File(r.imagenPath!).existsSync();
        } catch (_) {
          return false;
        }
      }
    })();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleReporteScreen(reporte: r)),
          );
        
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          r.imagenPath!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 96,
                            height: 96,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                          ),
                        )
                      : Image.file(
                          File(r.imagenPath!),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                )
              else
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.descripcion,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.ubicacion.isNotEmpty ? r.ubicacion : 'Ubicación no disponible',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // tags display
                    if (r.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: r.tags.map((t) {
                          return Chip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.blue.shade50,
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _fechaCorta(r.fecha),
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Reporte> items) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No hay reportes.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadReportes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildListTile(items[index]),
    );
  }

  String _fechaCorta(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _mostrarDetalle(Reporte r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleReporteScreen(reporte: r)),
    );
  }

  /*Future<void> _copiarAlPortapapeles(String texto) async {
    try {
      await Clipboard.setData(ClipboardData(text: texto));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al copiar: $e')));
      }
    }
  }*/

  // safe display for usuario
  String _usuarioDisplay(Reporte r) {
    try {
      final u = r.usuario;
      if (u == null) return 'Anónimo';
      final dyn = u as dynamic;
      if (dyn.nombre != null && dyn.nombre.toString().isNotEmpty) return dyn.nombre.toString();
      if (dyn.email != null && dyn.email.toString().isNotEmpty) return dyn.email.toString();
      if (dyn.correo != null && dyn.correo.toString().isNotEmpty) return dyn.correo.toString();
      // fallback to toJson map
      try {
        final map = dyn.toJson();
        if (map is Map) {
          final candidate = map['nombre'] ?? map['email'] ?? map['correo'] ?? map['username'];
          if (candidate != null) return candidate.toString();
        }
      } catch (_) {}
      return 'Anónimo';
    } catch (_) {
      return 'Anónimo';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBodyContent();
  }

  Widget _buildBodyContent() {
    final perdidos = _reportes.where(_esPerdido).toList();
    final encontrados = _reportes.where(_esEncontrado).toList();

    final mq = MediaQuery.of(context);
    final bool isWide = mq.size.width >= 800 || mq.orientation == Orientation.landscape;

    if (isWide) {
      // mostrar ambas listas lado a lado
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.sentiment_dissatisfied),
                      const SizedBox(width: 8),
                      const Text('Perdidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (!_loading) Text('${perdidos.length}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(onRefresh: _loadReportes, child: _buildList(perdidos)),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      const Text('Encontrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (!_loading) Text('${encontrados.length}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(onRefresh: _loadReportes, child: _buildList(encontrados)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Pantalla angosta: usar pestañas
    return Column(
      children: [
        Material(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Perdidos'), Tab(text: 'Encontrados')],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(onRefresh: _loadReportes, child: _buildList(perdidos)),
              RefreshIndicator(onRefresh: _loadReportes, child: _buildList(encontrados)),
            ],
          ),
        ),
      ],
    );
  }
}


class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(12.0),
        child: ReportesWidget(),
      ),
    );
  }
}