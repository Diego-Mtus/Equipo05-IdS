import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:objetos_perdidos/algoritmo_coincidencias.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/usuario.dart';

Reporte _crear({
  required String id,
  required TipoObjeto tipo,
  required String descripcion,
  required List<String> tags,
  required DateTime fecha,
  required double lat,
  required double lon,
}) {
  return Reporte(
    id: id,
    descripcion: descripcion,
    ubicacion: "Lugar",
    tags: tags,
    fecha: fecha,
    tipo: tipo,
    usuario: Usuario(
      nombre: "Test",
      correo: "test@udec.cl",
      nMatricula: '2023123123',
    ),
    coordenadas: LatLng(lat, lon),
  );
}

void main() {
  group("AlgoritmoCoincidencia - Tests", () {
    test("DESCARTA si la fecha del perdido es posterior al encontrado", () {
      final perdido = _crear(
        id: "p1",
        tipo: TipoObjeto.perdido,
        descripcion: "Celular negro",
        tags: ["celular"],
        fecha: DateTime(2024, 5, 20),
        lat: -36.8201,
        lon: -73.0443,
      );

      final encontrado = _crear(
        id: "e1",
        tipo: TipoObjeto.encontrado,
        descripcion: "Celular",
        tags: ["celular"],
        fecha: DateTime(2024, 5, 18),
        lat: -36.8201,
        lon: -73.0443,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(perdido, encontrado);
      expect(peso, 0);
    });

    test("DESCARTA si la distancia es > 600m", () {
      final p = _crear(
        id: "p2",
        tipo: TipoObjeto.perdido,
        descripcion: "Mochila negra",
        tags: ["mochila"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e2",
        tipo: TipoObjeto.encontrado,
        descripcion: "Mochila",
        tags: ["mochila"],
        fecha: DateTime(2024, 5, 11),
        lat: -36.8301, // ~1.1 km aprox
        lon: -73.0543,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, 0);
    });

    test("Alta coincidencia: <150m + 2 tags iguales", () {
      final p = _crear(
        id: "p3",
        tipo: TipoObjeto.perdido,
        descripcion: "Mochila azul grande",
        tags: ["mochila", "azul", "grande"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e3",
        tipo: TipoObjeto.encontrado,
        descripcion: "Mochila azul",
        tags: ["mochila", "azul"],
        fecha: DateTime(2024, 5, 11),
        lat: -36.8202, // muy cerca (<150 m)
        lon: -73.0442,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, greaterThan(0.70));
    });

    test("Debe ignorar tildes y comparar correctamente tags", () {
      final p = _crear(
        id: "p4",
        tipo: TipoObjeto.perdido,
        descripcion: "Cartera café",
        tags: ["café"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e4",
        tipo: TipoObjeto.encontrado,
        descripcion: "Cartera cafe",
        tags: ["cafe"],
        fecha: DateTime(2024, 5, 11),
        lat: -36.8201,
        lon: -73.0443,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, greaterThan(0.5));
    });

    test("Debe ignorar palabras comunes en descripción", () {
      final p = _crear(
        id: "p5",
        tipo: TipoObjeto.perdido,
        descripcion: "Mochila con los cuadernos y lápices",
        tags: ["mochila"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e5",
        tipo: TipoObjeto.encontrado,
        descripcion: "Mochila cuadernos lapices",
        tags: ["mochila"],
        fecha: DateTime(2024, 5, 11),
        lat: -36.8201,
        lon: -73.0443,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, greaterThan(0.4));
    });

    test("Peso debe ser más alto cuando las fechas están muy cercanas", () {
      final p = _crear(
        id: "p6",
        tipo: TipoObjeto.perdido,
        descripcion: "Llavero rojo",
        tags: ["llavero"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e6",
        tipo: TipoObjeto.encontrado,
        descripcion: "Llavero rojo plastico",
        tags: ["llavero", "rojo"],
        fecha: DateTime(2024, 5, 10, 5), // mismo día
        lat: -36.8201,
        lon: -73.0443,
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, greaterThan(0.6));
    });

    test("Coincidencia válida pero débil (pocos tags y nada cerca, ~400m)", () {
      final p = _crear(
        id: "p7",
        tipo: TipoObjeto.perdido,
        descripcion: "Bolso deportivo",
        tags: ["bolso"],
        fecha: DateTime(2024, 5, 10),
        lat: -36.8201,
        lon: -73.0443,
      );

      final e = _crear(
        id: "e7",
        tipo: TipoObjeto.encontrado,
        descripcion: "Bolso azul",
        tags: ["bolso"],
        fecha: DateTime(2024, 5, 13),
        lat: -36.8237, // aprox 400m al sur
        lon: -73.0443, // misma longitud
      );

      final peso = AlgoritmoCoincidencia.calcularPeso(p, e);
      expect(peso, inInclusiveRange(0.0, 0.6));
    });
  });
}
