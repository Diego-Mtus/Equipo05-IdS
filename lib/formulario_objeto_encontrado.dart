import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:objetos_perdidos/enum_tipo_objeto.dart';
import 'package:objetos_perdidos/formulario_datos_personales.dart';
import 'package:objetos_perdidos/reporte.dart';

class FormularioObjetoEncontrado extends StatefulWidget {
  const FormularioObjetoEncontrado({super.key});

  @override
  State<FormularioObjetoEncontrado> createState() =>
      _FormularioObjetoEncontradoState();
}

class _FormularioObjetoEncontradoState extends State<FormularioObjetoEncontrado> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _tagsController = TextEditingController();

  List<String> _tags = [];
  DateTime? _fechaSeleccionada;
  File? _imagen;

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

  void _removerTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos obligatorios")),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Debe seleccionar una fecha aproximada")),
    );
    return;
  }

    // Se crea un reporte parcial, sin usuario todavia
    final reporteParcial = Reporte(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: _descripcionController.text.trim(),
      ubicacion: _ubicacionController.text.trim(),
      tags: _tags,
      fecha: _fechaSeleccionada ?? DateTime.now(),
      tipo: TipoObjeto.encontrado,
      usuario: null,
      imagenPath: _imagen?.path,
    );

    // Ir al formulario de datos personales (para task #6)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FormularioDatosPersonales(reportePrevio: reporteParcial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  labelText: 'Descripción del objeto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese una decripción' : null,
              ),
              const SizedBox(height: 16),
              // Ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación donde se encontró',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese una ubicación' : null,
              ),
              const SizedBox(height: 16),
              // Fecha
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaSeleccionada == null
                          ? 'Fecha aproximada: No seleccionada'
                          : 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _seleccionarFecha(context),
                    label: const Text('Elegir fecha'),
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tags
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Agregar tag',
                  suffixIcon: IconButton(
                    onPressed: _agregarTag,
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: (_) => _agregarTag(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removerTag(tag),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Imagen
              _imagen == null
                  ? const Text('No se ha seleccionado imagen.')
                  : (kIsWeb
                        ? Image.network(_imagen!.path, height: 150)
                        : Image.file(_imagen!, height: 150)),
              TextButton.icon(
                onPressed: _seleccionarImagen,
                icon: const Icon(Icons.image),
                label: const Text('Agregar imagen (opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _enviarFormulario,
                label: const Text("Enviar reporte"),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
