import 'dart:convert';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Coincidencia {
  String idUnico;
  Reporte reportePerdido;
  Reporte reporteEncontrado;
  double peso;
  DateTime fechaDeteccion;
  EstadoCoincidencia estado;

  Coincidencia({
    required this.reportePerdido,
    required this.reporteEncontrado,
    required this.peso,
    required this.fechaDeteccion,
    required this.estado,
  }) : idUnico = "${reportePerdido.id}-${reporteEncontrado.id}";

  Map<String, dynamic> toJson() => {
    'idUnico': idUnico,
    'reportePerdido': reportePerdido.toJson(),
    'reporteEncontrado': reporteEncontrado.toJson(),
    'peso': peso,
    'fechaDeteccion': fechaDeteccion.toIso8601String(),
    'estado': estado.name,
  };

  factory Coincidencia.fromJson(Map<String, dynamic> json) {
    return Coincidencia(
      reportePerdido: Reporte.fromJson(json['reportePerdido']),
      reporteEncontrado: Reporte.fromJson(json['reporteEncontrado']),
      peso: (json['peso'] as num).toDouble(),
      fechaDeteccion: DateTime.parse(json['fechaDeteccion']),
      estado: EstadoCoincidencia.values.firstWhere(
        (e) => e.name == json['estado'],
      ),
    );
  }
}

Future<void> _guardarCoincidenciasLocal(List<Coincidencia> lista) async {
  final local = await SharedPreferences.getInstance();
  final jsonList = lista.map((c) => c.toJson()).toList();
  await local.setString('coincidencias', jsonEncode(jsonList));
}

Future<List<Coincidencia>> obtenerCoincidenciasLocales() async {
  final local = await SharedPreferences.getInstance();
  final jsonString = local.getString('coincidencias');
  if (jsonString == null) return [];

  final List<dynamic> listaJson = jsonDecode(jsonString);
  return listaJson.map((json) => Coincidencia.fromJson(json)).toList();
}

Future<void> agregarCoincidenciaLocal(Coincidencia nueva) async {
  final coincidencias = await obtenerCoincidenciasLocales();
  coincidencias.add(nueva);
  await _guardarCoincidenciasLocal(coincidencias);
}

Future<void> eliminarTodasLasCoincidencias() async {
  final local = await SharedPreferences.getInstance();
  await local.remove('coincidencias');
}
