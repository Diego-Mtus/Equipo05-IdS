import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/coincidencia.dart';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';
import 'package:objetos_perdidos/detalle_coincidencia.dart';

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class CoincidenciasWidget extends StatefulWidget {
  const CoincidenciasWidget({Key? key}) : super(key: key);

  @override
  State<CoincidenciasWidget> createState() => _CoincidenciasWidgetState();
}

class _CoincidenciasWidgetState extends State<CoincidenciasWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Coincidencia> _coincidencias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCoincidencias();
  }

  Future<void> _loadCoincidencias() async {
    setState(() => _loading = true);
    try {
      final lista = await obtenerCoincidenciasLocales();
      setState(() {
        _coincidencias = lista;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _coincidencias = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leyendo coincidencias: $e')));
      }
    }
  }

  Widget _buildListTile(Coincidencia c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => DetalleCoincidenciaScreen(coincidencia: c)),
          );
          if (changed == true) {
            _loadCoincidencias();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize('${c.reportePerdido.descripcion}'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text('Encontrado: ${_capitalize(c.reporteEncontrado.descripcion)}', overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Coincidencia: ${(c.peso * 100).toStringAsFixed(0)}%'),
                        const SizedBox(width: 12),
                        Text('Fecha: ${_fechaCorta(c.fechaDeteccion)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.chevron_right, color: Colors.grey[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Coincidencia> items) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No hay coincidencias.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCoincidencias,
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _coincidencias.where((c) => c.estado == EstadoCoincidencia.PENDIENTE).toList();
    final confirmadas = _coincidencias.where((c) => c.estado == EstadoCoincidencia.CONFIRMADA_POR_ADMIN).toList();

    final mq = MediaQuery.of(context);
    final bool isWide = mq.size.width >= 800 || mq.orientation == Orientation.landscape;

    if (isWide) {
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
                      const Text('Pendientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadCoincidencias,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Expanded(child: RefreshIndicator(onRefresh: _loadCoincidencias, child: _buildList(pendientes))),
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
                      const Text('Confirmadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadCoincidencias,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Expanded(child: RefreshIndicator(onRefresh: _loadCoincidencias, child: _buildList(confirmadas))),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Material(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Pendientes'), Tab(text: 'Confirmadas')],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(onRefresh: _loadCoincidencias, child: _buildList(pendientes)),
              RefreshIndicator(onRefresh: _loadCoincidencias, child: _buildList(confirmadas)),
            ],
          ),
        ),
      ],
    );
  }
}

class CoincidenciasScreen extends StatelessWidget {
  const CoincidenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coincidencias')),
      body: const Padding(padding: EdgeInsets.all(12.0), child: CoincidenciasWidget()),
    );
  }
}

