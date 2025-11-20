import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart'; // Asegúrate de tener este import
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/formulario_datos_personales.dart';
import 'package:objetos_perdidos/reporte.dart';
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
  File? _imagen;
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
    if (seleccionada != null) setState(() => _fechaSeleccionada = seleccionada);
  }

  // Imagen
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final seleccion = await picker.pickImage(source: ImageSource.gallery);
    if (seleccion != null) setState(() => _imagen = File(seleccion.path));
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

  Future<void> _seleccionarUbicacionMapa() async {
    try {
      final LatLng? resultado = await Navigator.of(context).push<LatLng?>(
        MaterialPageRoute(
          builder: (context) => SelectorMapaUdec(
            ubicacionInicial: _coordenadasGuardadas,
          ),
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

  void _removerTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _enviarFormulario() async {

    bool formValido = _formKey.currentState!.validate();


    setState(() {
      _errorUbicacion = _coordenadasGuardadas == null;
    });


    if (!formValido || _errorUbicacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete los campos obligatorios (Descripción y Ubicación)")),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe seleccionar una fecha aproximada")),
      );
      return;
    }

    final textoUbicacion = "Lat: ${_coordenadasGuardadas!.latitude.toStringAsFixed(5)}, Lng: ${_coordenadasGuardadas!.longitude.toStringAsFixed(5)}";

    final reporteParcial = Reporte(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: _descripcionController.text.trim(),
      ubicacion: textoUbicacion, 
      tags: _tags,
      fecha: _fechaSeleccionada ?? DateTime.now(),
      tipo: TipoObjeto.encontrado,
      usuario: null,
      imagenPath: _imagen?.path,
      coordenadas: _coordenadasGuardadas,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FormularioDatosPersonales(reportePrevio: reporteParcial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Color del borde dependiendo si hay error o no
    final colorBorde = _errorUbicacion ? Colors.red : Colors.grey;

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de objeto encontrado')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción del objeto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 20),


              const Text(
                "Ubicación del hallazgo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              Material(
                color: Colors.white,
                elevation: 2, 
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _seleccionarUbicacionMapa,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorBorde, width: 1.5),
                    ),
                    child: Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _coordenadasGuardadas != null 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _coordenadasGuardadas != null ? Icons.location_on : Icons.map,
                            color: _coordenadasGuardadas != null ? Colors.green : Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Texto descriptivo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _coordenadasGuardadas != null 
                                  ? "Ubicación seleccionada" 
                                  : "Toca para ubicar en el mapa",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _coordenadasGuardadas != null ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                              if (_coordenadasGuardadas != null)
                                Text(
                                  "Lat: ${_coordenadasGuardadas!.latitude.toStringAsFixed(4)}...",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),

                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ),

              if (_errorUbicacion)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 5),
                  child: Text(
                    "Debe seleccionar una ubicación en el mapa",
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 20),
              
              // Fecha
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _fechaSeleccionada == null
                      ? 'Seleccionar fecha aproximada'
                      : 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                  style: TextStyle(
                      color: _fechaSeleccionada == null ? Colors.grey[600] : Colors.black
                  ),
                ),
                onTap: () => _seleccionarFecha(context),
              ),
              const Divider(),

              const SizedBox(height: 10),
              // Tags
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Etiquetas (Ej: llaves, azul)',
                  hintText: 'Escribe y presiona +',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _agregarTag,
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                  ),
                ),
                onSubmitted: (_) => _agregarTag(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _removerTag(tag),
                          backgroundColor: Colors.blue.shade50,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              
              // Imagen
              _imagen == null
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(_imagen!.path, height: 150, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(_imagen!, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
              TextButton.icon(
                onPressed: _seleccionarImagen,
                icon: Icon(_imagen == null ? Icons.camera_alt : Icons.refresh),
                label: Text(_imagen == null ? 'Adjuntar foto (Opcional)' : 'Cambiar foto'),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _enviarFormulario,
                  child: const Text("Siguiente Paso", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}