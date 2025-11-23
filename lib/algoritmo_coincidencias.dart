import 'package:latlong2/latlong.dart';
import 'package:objetos_perdidos/reporte.dart';

class AlgoritmoCoincidencia {
  static final Distance _distancia = Distance();

  // Palabras irrelevantes en descripciones
  static final Set<String> _stopWords = {
    'los',
    'las',
    'el',
    'la',
    'con',
    'tambien',
    'también',
    'ademas',
    'además',
    'de',
    'del',
    'un',
    'una',
    'unos',
    'unas',
    'para',
    'por',
    'y',
    'en',
  };

  /// Calcula un peso entre 0 y 1. Retorna 0.0 si los criterios obligatorios fallan.
  static double calcularPeso(Reporte perdido, Reporte encontrado) {
    // DESCARTE POR FECHAS.
    if (perdido.fecha.isAfter(encontrado.fecha) == true) {
      return 0.0; // objeto encontrado NO puede ser anterior
    }

    // DESCARTE POR DISTANCIA > 600m
    final metros = _metros(perdido.coordenadas, encontrado.coordenadas);
    if (metros == null || metros > 600) return 0.0;

    // PESO DE TAGS
    final pesoTags = _pesoTags(perdido.tags, encontrado.tags);

    // PESO DE DESCRIPCIÓN
    final pesoDescripcion = _pesoDescripcion(
      perdido.descripcion,
      encontrado.descripcion,
    );

    // Si no hay coincidencias reales (tags o palabras clave),
    // la distancia NO debe aportar peso
    final hayCoincidenciasTextuales = pesoTags > 0.2 || pesoDescripcion > 0.2;

    // PESO DE DISTANCIA
    final pesoDistancia = hayCoincidenciasTextuales
        ? _pesoDistancia(metros)
        : 0.0;

    // PESO DE FECHAS (mientras más cercano, más peso)
    final pesoFechas = _pesoFechas(perdido.fecha, encontrado.fecha);

    // CASO ESPECIAL: distancia <150m + 2 tags en común = peso alto
    final tagsEnComun = _tagsEnComun(perdido.tags, encontrado.tags);
    final descEnComun = _descripcionEnComun(
      perdido.descripcion,
      encontrado.descripcion,
    );

    if (metros < 150 && (tagsEnComun >= 2 || descEnComun >= 3)) {
      return 0.9 + (0.1 * pesoFechas);
    }

    final pesoTotal =
        0.35 * pesoTags +
        0.30 * pesoDescripcion +
        0.20 * pesoDistancia +
        0.15 * pesoFechas;

    if (!hayCoincidenciasTextuales) {
      return pesoTotal.clamp(0.0, 0.5);
    }
    return double.parse(pesoTotal.clamp(0.0, 1.0).toStringAsFixed(4));
  }

  // TAGS

  static int _tagsEnComun(List<String> t1, List<String> t2) {
    final set1 = t1.map(_normalizar).toSet();
    final set2 = t2.map(_normalizar).toSet();
    return set1.intersection(set2).length;
  }

  static double _pesoTags(List<String> t1, List<String> t2) {
    if (t1.isEmpty || t2.isEmpty) return 0;
    final set1 = t1.map(_normalizar).toSet();
    final set2 = t2.map(_normalizar).toSet();
    return set1.intersection(set2).length / set1.union(set2).length;
  }

  // DESCRIPCIÓN

  static double _pesoDescripcion(String a, String b) {
    final palabras1 = _tokenizar(a);
    final palabras2 = _tokenizar(b);

    if (palabras1.isEmpty || palabras2.isEmpty) return 0;

    final inter = palabras1.intersection(palabras2).length;
    final union = palabras1.union(palabras2).length;

    return inter / union;
  }

  // Contar cuántas palabras relevantes están en común en la descripción
  static int _descripcionEnComun(String a, String b) {
    final palabrasA = _tokenizar(a);
    final palabrasB = _tokenizar(b);
    return palabrasA.intersection(palabrasB).length;
  }

  static Set<String> _tokenizar(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\wáéíóúñ ]'), '')
        .split(RegExp(r'\s+'))
        .map(_normalizar)
        .where((p) => p.length >= 3 && !_stopWords.contains(p))
        .toSet();
  }

  // DISTANCIA

  static double? _metros(LatLng? c1, LatLng? c2) {
    if (c1 == null || c2 == null) return null;
    return _distancia.as(LengthUnit.Meter, c1, c2);
  }

  static double _pesoDistancia(double metros) {
    // 0m es peso 1.0
    // 600m es peso 0.0
    return (1 - (metros / 600)).clamp(0, 1).toDouble();
  }

  // FECHAS
  static double _pesoFechas(DateTime perdido, DateTime encontrado) {
    final horas = encontrado.difference(perdido).inHours.abs();
    // 0h es 1.0
    // 96h (4 días) es 0.0
    return (1 - (horas / 96)).clamp(0, 1).toDouble();
  }

  // Util

  static String _normalizar(String s) {
    // quitar tildes y pasar a minúsculas
    final mapa = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'a',
      'É': 'e',
      'Í': 'i',
      'Ó': 'o',
      'Ú': 'u',
      'ñ': 'n',
      'Ñ': 'n',
    };
    return s.toLowerCase().split('').map((c) => mapa[c] ?? c).join();
  }
}
