import 'package:objetos_perdidos/algoritmo_coincidencias.dart';
import 'package:objetos_perdidos/coincidencia.dart';
import 'package:objetos_perdidos/enum_estado_coincidencia.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/reporte.dart';

class CoincidenciaService {
  static const double UMBRAL = 0.65;

  // Detecta coincidencias solo para el reporte nuevo creado
  static Future<void> detectarCoincidenciasParaNuevoReporte(
    Reporte nuevo,
  ) async {
    // Cargar reportes
    final todos = await obtenerReportesLocales();

    // Definir "opuestos"
    List<Reporte> reportesOpuestos;

    if (nuevo.tipo == TipoObjeto.perdido) {
      reportesOpuestos = todos
          .where((r) => r.tipo == TipoObjeto.encontrado)
          .toList();
    } else {
      reportesOpuestos = todos
          .where((r) => r.tipo == TipoObjeto.perdido)
          .toList();
    }

    // Comparar nuevo reporte con los del tipo opuesto

    for (final otro in reportesOpuestos) {

      // Calcular peso
      final peso = nuevo.tipo == TipoObjeto.perdido
          ? AlgoritmoCoincidencia.calcularPeso(nuevo, otro)
          : AlgoritmoCoincidencia.calcularPeso(otro, nuevo);

      print("El peso de reporte con ${otro.descripcion} es de $peso");

      if (peso >= UMBRAL) {
        final coincidencia = Coincidencia(
          reportePerdido: nuevo.tipo == TipoObjeto.perdido ? nuevo : otro,
          reporteEncontrado: nuevo.tipo == TipoObjeto.encontrado ? nuevo : otro,
          peso: peso,
          fechaDeteccion: DateTime.now(),
          estado: EstadoCoincidencia.PENDIENTE,
        );

        await agregarCoincidenciaLocal(coincidencia);

      }
    }
  }
}
