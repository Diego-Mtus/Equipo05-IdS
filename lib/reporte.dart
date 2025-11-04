import 'dart:convert';

import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reporte {
  String id;
  String descripcion;
  String ubicacion;
  List<String> tags;
  DateTime fecha;
  TipoObjeto tipo;
  Usuario? usuario;
  String? imagenPath;

  Reporte({
    required this.id,
    required this.descripcion,
    required this.ubicacion,
    required this.tags,
    required this.fecha,
    required this.tipo,
    required this.usuario,
    this.imagenPath
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'descripcion': descripcion,
    'ubicacion': ubicacion,
    'fecha': fecha.toIso8601String(),
    'tipo': tipo.name,
    'usuario': usuario!.toJson(),
    'tags': tags,
  };

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
    id: json['id'],
    descripcion: json['descripcion'],
    ubicacion: json['ubicacion'],
    fecha: DateTime.parse(json['fecha']),
    tipo: TipoObjeto.values.firstWhere((e) => e.name == json['tipo']),
    usuario: Usuario.fromJson(json['usuario']),
    tags: (json['tags'] != null)
            ? List<String>.from(json['tags'])
            : [],
  );
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

// Para agregar reporte sin borrar anteriores
Future<void> agregarReporteLocal(Reporte nuevoReporte) async {
  final reportes = await obtenerReportesLocales();
  reportes.add(nuevoReporte);
  await _guardarListaLocal(reportes);
}

/// Para reiniciar reportes
Future<void> eliminarTodosLosReportes() async {
  final local = await SharedPreferences.getInstance();
  await local.remove('reportes');
}
