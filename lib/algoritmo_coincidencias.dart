import 'package:latlong2/latlong.dart';
import 'package:objetos_perdidos/reporte.dart';

class AlgoritmoCoincidencia {
  static final Distance _distancia = Distance();

  // Palabras irrelevantes en descripciones. Se normalizan (quita tildes)
  // para coincidir con tokens procesados por `_tokenizar`.
  static final Set<String> _stopWords = <String>{
    // artículos / determinantes
    'el', 'la', 'los', 'las', 'lo', 'un', 'una', 'unos', 'unas',
    // preposiciones / conjunciones
    'de',
    'del',
    'a',
    'ante',
    'bajo',
    'con',
    'contra',
    'por',
    'para',
    'entre',
    'sin',
    'sobre',
    'hacia',
    'hasta',
    'segun',
    'y', 'o', 'u', 'pero', 'porque', 'que', 'como', 'cuando', 'donde',
    // pronombres comunes
    'yo',
    'tu',
    'tus',
    'te',
    'usted',
    'ustedes',
    'ella',
    'ellos',
    'nos',
    'nosotros',
    'mi',
    'mis',
    'su',
    'sus',
    // verbos y formas frecuentes (variantes comunes relacionadas a pérdidas/encuentros)
    'perdi',
    'perdio',
    'encontre',
    'encontrado',
    'encontraron',
    'encontramos',
    'tengo',
    'tenia',
    // palabras de relleno / cortesía
    'hola', 'gracias', 'porfavor', 'favor', 'buenos', 'dias', 'tarde', 'noche',
    // referencias espaciales/tiempo no descriptivas
    'aqui', 'alli', 'cerca', 'lejos', 'frente', 'atras',
    // indicaciones de adjuntos/imagenes
    'foto', 'fotos', 'imagen', 'imagenes', 'adjunto', 'adjunta',
    // otras palabras cortas comunes que no aportan mucho
    'muy',
    'mas',
    'menos',
    'algo',
    'algun',
    'alguno',
    'algunos',
    'alguna',
    'algunas',
    'se', 'me', 'afuera', 'dentro',
  }.map(_normalizar).toSet();

  // Umbral de similitud normalizada (Levenshtein) para considerar tokens como "match"
  static const double _fuzzyThreshold = 0.9;

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

    // Contar tags en común
    final tagsEnComun = _tagsEnComun(perdido.tags, encontrado.tags);

    // Si no hay coincidencias textuales 'reales' (p.ej. al menos 2 tags en común
    // o una descripción suficientemente similar), la distancia NO debe aportar peso
    final hayCoincidenciasTextuales = tagsEnComun >= 2 || pesoDescripcion > 0.2;

    // PESO DE DISTANCIA
    final pesoDistancia = hayCoincidenciasTextuales
        ? _pesoDistancia(metros)
        : 0.0;

    // PESO DE FECHAS (mientras más cercano, más peso)
    final pesoFechas = _pesoFechas(perdido.fecha, encontrado.fecha);

    // CASO ESPECIAL: distancia <150m + 2 tags en común = peso alto
    final descEnComun = _descripcionEnComun(
      perdido.descripcion,
      encontrado.descripcion,
    );

    if (metros < 150 && (tagsEnComun >= 2 || descEnComun >= 2)) {
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

    final list1 = t1.map(_normalizar).toList();
    final list2 = t2.map(_normalizar).toList();

    // Conteo de matches usando comparación exacta primero y luego fuzzy
    final remaining = List<String>.from(list2);
    var matches = 0;

    for (final token in list1) {
      final exactIndex = remaining.indexOf(token);
      if (exactIndex != -1) {
        matches++;
        remaining.removeAt(exactIndex);
        continue;
      }

      // buscar mejor candidato fuzzy
      var bestSim = 0.0;
      var bestIdx = -1;
      for (var i = 0; i < remaining.length; i++) {
        final sim = _normalizedSimilarity(token, remaining[i]);
        if (sim > bestSim) {
          bestSim = sim;
          bestIdx = i;
        }
      }
      if (bestSim >= _fuzzyThreshold && bestIdx != -1) {
        matches++;
        remaining.removeAt(bestIdx);
      }
    }

    final set1 = list1.toSet();
    final set2 = list2.toSet();
    final unionSize = (set1.length + set2.length - matches).clamp(
      1,
      set1.length + set2.length,
    );
    return matches / unionSize;
  }

  // DESCRIPCIÓN

  static double _pesoDescripcion(String a, String b) {
    final palabras1 = _tokenizar(a).toList();
    final palabras2 = _tokenizar(b).toList();

    if (palabras1.isEmpty || palabras2.isEmpty) return 0;

    final remaining = List<String>.from(palabras2);
    var matches = 0;

    for (final p in palabras1) {
      final exactIndex = remaining.indexOf(p);
      if (exactIndex != -1) {
        matches++;
        remaining.removeAt(exactIndex);
        continue;
      }

      var bestSim = 0.0;
      var bestIdx = -1;
      for (var i = 0; i < remaining.length; i++) {
        final sim = _normalizedSimilarity(p, remaining[i]);
        if (sim > bestSim) {
          bestSim = sim;
          bestIdx = i;
        }
      }
      if (bestSim >= _fuzzyThreshold && bestIdx != -1) {
        matches++;
        remaining.removeAt(bestIdx);
      }
    }

    final setA = palabras1.toSet();
    final setB = palabras2.toSet();
    final unionSize = (setA.length + setB.length - matches).clamp(
      1,
      setA.length + setB.length,
    );
    return matches / unionSize;
  }

  // Levenshtein + normalizada a [0,1]
  static double _normalizedSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    final dist = _levenshtein(a, b);
    return 1.0 - (dist / maxLen);
  }

  static int _levenshtein(String s, String t) {
    final n = s.length;
    final m = t.length;
    if (n == 0) return m;
    if (m == 0) return n;

    final v = List<int>.filled(m + 1, 0);
    for (var j = 0; j <= m; j++) v[j] = j;

    for (var i = 1; i <= n; i++) {
      var prev = v[0];
      v[0] = i;
      for (var j = 1; j <= m; j++) {
        final temp = v[j];
        var cost = (s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1)) ? 0 : 1;
        v[j] = _min3(v[j] + 1, v[j - 1] + 1, prev + cost);
        prev = temp;
      }
    }
    return v[m];
  }

  static int _min3(int a, int b, int c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);

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
