import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/image_store.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/detalle_reporte.dart';
import 'package:objetos_perdidos/coincidencia.dart';
import 'package:objetos_perdidos/algoritmo_coincidencias.dart';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';

class ReportesWidget extends StatefulWidget {
  final bool isEncargado;

  const ReportesWidget({
    Key? key,
    this.isEncargado = false,
  }) : super(key: key);

  @override
  State<ReportesWidget> createState() => _ReportesWidgetState();
}

class _ReportesWidgetState extends State<ReportesWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Reporte> _reportes = [];
  bool _loading = true;
  bool get _esEncargado => widget.isEncargado;
  bool _modoCoincidencias = false;
  Reporte? _selPerdido;
  Reporte? selEncontrado;
  bool _confirmaCoincidencia = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leyendo reportes: $e')),
        );
      }
    }
  }

  bool _esPerdido(Reporte r) => r.tipo == TipoObjeto.perdido;
  bool _esEncontrado(Reporte r) => r.tipo == TipoObjeto.encontrado;

  Future<void> _confirmarEliminarReporte(Reporte r) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text(
          '¿Seguro que deseas eliminar este reporte? '
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await eliminarReporteLocal(r.id);
        setState(() {
          _reportes.removeWhere((rep) => rep.id == r.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el reporte: $e')),
          );
        }
      }
    }
  }

  Widget _buildListTile(Reporte r) {
    // Evitar el uso de APIs relacionadas con archivos en web
    final bool hasImage = (() {
      if (r.imagenPath == null || r.imagenPath!.isEmpty) return false;
      if (r.imagenPath!.startsWith('hive:')) {
        final id = r.imagenPath!.substring(5);
        return ImageStore.hasImageSync(id);
      }
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

    final bool estadoSeleccionReporte =
        (r.tipo == TipoObjeto.perdido && _selPerdido?.id == r.id) ||
            (r.tipo == TipoObjeto.encontrado && selEncontrado?.id == r.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: estadoSeleccionReporte
          ? RoundedRectangleBorder(
              side: BorderSide(
                  color: Colors.blueAccent.shade700, width: 2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: InkWell(
        onTap: () {
          if (_modoCoincidencias) {
            setState(() {
              if (r.tipo == TipoObjeto.perdido) {
                if (_selPerdido?.id == r.id) {
                  _selPerdido = null;
                } else {
                  _selPerdido = r;
                }
              } else {
                if (selEncontrado?.id == r.id) {
                  selEncontrado = null;
                } else {
                  selEncontrado = r;
                }
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DetalleReporteScreen(reporte: r, backEnable: true),
              ),
            );
          }
        },
        onLongPress: () {
          // Activa modo de creación de coincidencia
          setState(() {
            _modoCoincidencias = true;
            if (r.tipo == TipoObjeto.perdido) {
              _selPerdido = r;
            } else {
              selEncontrado = r;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (() {
                    if (r.imagenPath!.startsWith('hive:')) {
                      final id = r.imagenPath!.substring(5);
                      final bytes =
                          ImageStore.loadReportImageSync(id);
                      if (bytes != null) {
                        return Image.memory(
                          bytes,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        width: 96,
                        height: 96,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          size: 36,
                          color: Colors.grey,
                        ),
                      );
                    }

                    if (kIsWeb) {
                      return Image.network(
                        r.imagenPath!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 36,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return Image.file(
                      File(r.imagenPath!),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    );
                  })(),
                )
              else
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.descripcion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.ubicacion.isNotEmpty
                                ? r.ubicacion
                                : 'Ubicación no disponible',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
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
                            label: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            visualDensity:
                                VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap,
                            backgroundColor:
                                Colors.blue.shade50,
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fechaCorta(r.fecha),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_modoCoincidencias)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    estadoSeleccionReporte
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: estadoSeleccionReporte
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
                )
              else if (_esEncargado)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  tooltip: 'Eliminar reporte',
                  onPressed: () =>
                      _confirmarEliminarReporte(r),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Reporte> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
      itemBuilder: (context, index) =>
          _buildListTile(items[index]),
    );
  }

  String _fechaCorta(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmarCoincidenciaSeleccionada() async {
    if (_selPerdido == null || selEncontrado == null) return;
    setState(() => _confirmaCoincidencia = true);
    try {
      final peso = AlgoritmoCoincidencia.calcularPeso(
        _selPerdido!,
        selEncontrado!,
      );
      final nueva = Coincidencia(
        reportePerdido: _selPerdido!,
        reporteEncontrado: selEncontrado!,
        peso: peso,
        fechaDeteccion: DateTime.now(),
        estado: EstadoCoincidencia.CONFIRMADA_POR_ADMIN,
      );
      await agregarCoincidenciaLocal(nueva);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Coincidencia creada y confirmada'),
          ),
        );
      }
      // reset selection and exit select mode
      setState(() {
        _modoCoincidencias = false;
        _selPerdido = null;
        selEncontrado = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error creando coincidencia: $e'),
          ),
        );
      }
    } finally {
      setState(() => _confirmaCoincidencia = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBodyContent() {
    final perdidos = _reportes.where(_esPerdido).toList();
    final encontrados =
        _reportes.where(_esEncontrado).toList();

    final mq = MediaQuery.of(context);
    final bool isWide = mq.size.width >= 800 ||
        mq.orientation == Orientation.landscape;

    if (isWide) {
      // mostrar ambas listas lado a lado
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.sentiment_dissatisfied),
                      const SizedBox(width: 8),
                      const Text(
                        'Perdidos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!_loading)
                        Text(
                          '${perdidos.length}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReportes,
                    child: _buildList(perdidos),
                  ),
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
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      const Text(
                        'Encontrados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!_loading)
                        Text(
                          '${encontrados.length}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReportes,
                    child: _buildList(encontrados),
                  ),
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
            tabs: const [
              Tab(text: 'Perdidos'),
              Tab(text: 'Encontrados'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _loadReportes,
                child: _buildList(perdidos),
              ),
              RefreshIndicator(
                onRefresh: _loadReportes,
                child: _buildList(encontrados),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget de instrucción (pequeño, no superpuesto) colocado debajo de las listas/pestañas
    final instruccionCoincide = !_modoCoincidencias
        ? Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.black54,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mantén presionado un reporte para establecer una coincidencia',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildBodyContent(),
              // controles de selección
              if (_modoCoincidencias)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Material(
                    elevation: 6,
                    borderRadius:
                        BorderRadius.circular(8),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Seleccionados: Perdido=${_selPerdido?.descripcion != null ? (_selPerdido!.descripcion.length > 30 ? _selPerdido!.descripcion.substring(0, 30) + '...' : _selPerdido!.descripcion) : '—'}  •  Encontrado=${selEncontrado?.descripcion != null ? (selEncontrado!.descripcion.length > 30 ? selEncontrado!.descripcion.substring(0, 30) + '...' : selEncontrado!.descripcion) : '—'}',
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _confirmaCoincidencia
                                ? null
                                : () => setState(() {
                                      _modoCoincidencias =
                                          false;
                                      _selPerdido = null;
                                      selEncontrado = null;
                                    }),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (_selPerdido != null &&
                                        selEncontrado !=
                                            null &&
                                        !_confirmaCoincidencia)
                                ? _confirmarCoincidenciaSeleccionada
                                : null,
                            child: _confirmaCoincidencia
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            8,
            12,
            12,
          ),
          child: instruccionCoincide,
        ),
      ],
    );
  }
}

class ReportesScreen extends StatelessWidget {
  final bool isEncargado;

  const ReportesScreen({
    super.key,
    this.isEncargado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ReportesWidget(isEncargado: isEncargado),
      ),
    );
  }
}
