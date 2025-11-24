import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/formulario_datos_personales.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/image_store.dart';
import 'package:objetos_perdidos/selector_mapa_udec.dart';

class FormularioObjetoEncontrado extends StatefulWidget {
  const FormularioObjetoEncontrado({super.key});

  @override
  State<FormularioObjetoEncontrado> createState() =>
      _FormularioObjetoEncontradoState();
}

class _FormularioObjetoEncontradoState
    extends State<FormularioObjetoEncontrado> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _tagsController = TextEditingController();

  List<String> _tags = [];
  DateTime? _fechaSeleccionada;
  Uint8List? _imagenBytes;
  LatLng? _coordenadasGuardadas;

  bool _errorUbicacion = false;

  // Fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      firstDate: DateTime(hoy.year - 1),
      lastDate: hoy,
      initialDate: hoy,
    );
    if (seleccionada != null) {
      setState(() => _fechaSeleccionada = seleccionada);
    }
  }

  // Imagen
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final seleccion = await picker.pickImage(source: ImageSource.gallery);

    if (seleccion != null) {
      final bytes = await seleccion.readAsBytes();
      setState(() => _imagenBytes = bytes);
    }
  }

  // Tags
  void _agregarTag() {
    final texto = _tagsController.text.trim();
    if (texto.isNotEmpty && !_tags.contains(texto)) {
      setState(() {
        _tags.add(texto);
        _tagsController.clear();
      });
    }
  }

  void _removerTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  // Ubicación con mapa
  Future<void> _seleccionarUbicacionMapa() async {
    try {
      final LatLng? resultado = await Navigator.push<LatLng?>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SelectorMapaUdec(ubicacionInicial: _coordenadasGuardadas),
        ),
      );

      if (!mounted) return;

      if (resultado != null) {
        setState(() {
          _coordenadasGuardadas = resultado;
          _errorUbicacion = false;
        });
      }
    } catch (e) {
      debugPrint("Error mapa: $e");
    }
  }

  Future<void> _enviarFormulario() async {
    bool formValido = _formKey.currentState!.validate();

    setState(() => _errorUbicacion = _coordenadasGuardadas == null);

    if (!formValido || _errorUbicacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete los campos obligatorios"),
        ),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar una fecha aproximada"),
        ),
      );
      return;
    }

    final ubicacionString =
        "Lat: ${_coordenadasGuardadas!.latitude.toStringAsFixed(5)}, Lng: ${_coordenadasGuardadas!.longitude.toStringAsFixed(5)}";

    final reporteParcial = Reporte(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: _descripcionController.text.trim(),
      ubicacion: ubicacionString,
      tags: _tags,
      fecha: _fechaSeleccionada!,
      tipo: TipoObjeto.encontrado,
      usuario: null,
      imagenPath: _imagenBytes != null ? 'hive:${DateTime.now().millisecondsSinceEpoch.toString()}' : null,
      coordenadas: _coordenadasGuardadas,
    );

    if (_imagenBytes != null) {
      final id = reporteParcial.id;
      await ImageStore.saveReportImage(id, _imagenBytes!);
      reporteParcial.imagenPath = 'hive:$id';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDatosPersonales(
          reportePrevio: reporteParcial,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bordeUbicacion = Border.all(
      color: _errorUbicacion ? Colors.red : theme.colorScheme.primary,
      width: 1.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Objeto encontrado"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- DESCRIPCIÓN ---
              _CardSeccion(
                titulo: "Descripción",
                icono: Icons.description_outlined,
                child: TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Describe el objeto",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Este campo es obligatorio" : null,
                ),
              ),

              const SizedBox(height: 20),

              // --- UBICACIÓN ---
              _CardSeccion(
                titulo: "Ubicación del hallazgo",
                icono: Icons.location_on_outlined,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _seleccionarUbicacionMapa,
                  child: Container(
                    decoration: BoxDecoration(
                      border: bordeUbicacion,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _coordenadasGuardadas != null
                              ? Icons.check_circle
                              : Icons.map,
                          color: _coordenadasGuardadas != null
                              ? Colors.green
                              : theme.colorScheme.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _coordenadasGuardadas != null
                                ? "Ubicación seleccionada\nLat: ${_coordenadasGuardadas!.latitude.toStringAsFixed(4)}, Lng: ${_coordenadasGuardadas!.longitude.toStringAsFixed(4)}"
                                : "Toca para seleccionar en el mapa",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              if (_errorUbicacion)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 6),
                  child: Text(
                    "Debe seleccionar una ubicación",
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 20),

              // --- FECHA ---
              _CardSeccion(
                titulo: "Fecha aproximada",
                icono: Icons.calendar_month,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _fechaSeleccionada == null
                        ? "Seleccionar fecha"
                        : "${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}",
                    style: TextStyle(
                      color: _fechaSeleccionada == null
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                  onTap: () => _seleccionarFecha(context),
                ),
              ),

              const SizedBox(height: 20),

              // --- TAGS ---
              _CardSeccion(
                titulo: "Etiquetas",
                icono: Icons.sell_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: "Agregar etiqueta",
                        suffixIcon: IconButton(
                          onPressed: _agregarTag,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _agregarTag(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: _tags
                          .map((t) => Chip(
                                label: Text(t),
                                onDeleted: () => _removerTag(t),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- IMAGEN ---
              _CardSeccion(
                titulo: "Fotografía (opcional)",
                icono: Icons.camera_alt_outlined,
                child: Column(
                  children: [
                    if (_imagenBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imagenBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _seleccionarImagen,
                      icon: Icon(_imagenBytes == null ? Icons.photo_camera : Icons.refresh),
                      label: Text(_imagenBytes == null ? "Adjuntar foto" : "Cambiar foto"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- BOTÓN SIGUIENTE ---
              SizedBox(
                height: 55,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _enviarFormulario,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    "Siguiente paso",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Widget para las secciones
class _CardSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const _CardSeccion({
    required this.titulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
