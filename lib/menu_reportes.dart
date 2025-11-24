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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reportes'),
            Tab(text: 'Coincidencias'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              Center(child: Text('Lista de reportes')),
              Center(child: Text('Lista de coincidencias')),
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
