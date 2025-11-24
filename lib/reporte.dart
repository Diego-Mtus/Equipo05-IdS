import 'dart:convert';

import 'package:latlong2/latlong.dart'; 
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:objetos_perdidos/image_store.dart';

class Reporte {
  String id;
  String descripcion;
  String ubicacion;
  List<String> tags;
  DateTime fecha;
  TipoObjeto tipo;
  Usuario? usuario;
  String? imagenPath;

  LatLng? coordenadas; 

  Reporte({
    required this.id,
    required this.descripcion,
    required this.ubicacion,
    required this.tags,
    required this.fecha,
    required this.tipo,
    required this.usuario,
    this.imagenPath,
    this.coordenadas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'descripcion': descripcion,
    'ubicacion': ubicacion,
    'fecha': fecha.toIso8601String(),
    'tipo': tipo.name,
    'usuario': usuario?.toJson(),
    'tags': tags,
    'imagenPath': imagenPath,

    'latitud': coordenadas?.latitude,
    'longitud': coordenadas?.longitude,
  };

  factory Reporte.fromJson(Map<String, dynamic> json) {

    LatLng? coordsLeidas;
    if (json['latitud'] != null && json['longitud'] != null) {
      coordsLeidas = LatLng(
        (json['latitud'] as num).toDouble(), 
        (json['longitud'] as num).toDouble()
      );
    }

    return Reporte(
      id: json['id'],
      descripcion: json['descripcion'],
      ubicacion: json['ubicacion'],
      fecha: DateTime.parse(json['fecha']),
      tipo: TipoObjeto.values.firstWhere((e) => e.name == json['tipo']),
      // Manejo seguro de usuario nulo
      usuario: json['usuario'] != null 
          ? Usuario.fromJson(json['usuario']) 
          : null, 
      tags: (json['tags'] != null)
            ? List<String>.from(json['tags'])
            : [],
      imagenPath: json['imagenPath'],
      coordenadas: coordsLeidas, // Asignamos lo reconstruido
    );
  }
}



Future<void> _guardarListaLocal(List<Reporte> reportes) async {
  final local = await SharedPreferences.getInstance();
  final listaJson = reportes.map((r) => r.toJson()).toList();
  await local.setString('reportes', jsonEncode(listaJson));
}

Future<List<Reporte>> obtenerReportesLocales() async {
  final local = await SharedPreferences.getInstance();
  final jsonString = local.getString('reportes');
  if (jsonString == null) return [];
  
  final List<dynamic> listaJson = jsonDecode(jsonString);
  return listaJson.map((json) => Reporte.fromJson(json)).toList();
}

Future<void> agregarReporteLocal(Reporte nuevoReporte) async {
  final reportes = await obtenerReportesLocales();
  reportes.add(nuevoReporte);
  await _guardarListaLocal(reportes);
}

Future<void> eliminarTodosLosReportes() async {

  final reportes = await obtenerReportesLocales();
  for (final r in reportes) {
    if (r.imagenPath != null && r.imagenPath!.startsWith('hive:')) {
      final id = r.imagenPath!.substring(5);
      try {
        await ImageStore.deleteReportImage(id);
      } catch (_) {}
    }
  }

  final local = await SharedPreferences.getInstance();
  await local.remove('reportes');
}


Future<void> eliminarReporteLocal(String reportId) async {
  final reportes = await obtenerReportesLocales();
  final index = reportes.indexWhere((r) => r.id == reportId);
  if (index == -1) return;

  final removed = reportes.removeAt(index);
  await _guardarListaLocal(reportes);

  if (removed.imagenPath != null && removed.imagenPath!.startsWith('hive:')) {
    final id = removed.imagenPath!.substring(5);
    try {
      await ImageStore.deleteReportImage(id);
    } catch (_) {}
  }
}