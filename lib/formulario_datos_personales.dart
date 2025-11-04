import 'package:flutter/material.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/usuario.dart';

class FormularioDatosPersonales extends StatefulWidget {
  final Reporte reportePrevio;

  const FormularioDatosPersonales({super.key, required this.reportePrevio});

  @override
  State<FormularioDatosPersonales> createState() =>
      _FormularioDatosPersonalesState();
}

class _FormularioDatosPersonalesState extends State<FormularioDatosPersonales> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _matriculaController = TextEditingController();

  // Función para finalizar reporte
  Future<void> _finalizarReporte() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete todos los campos correctamente'),
        ),
      );
      return;
    }

    // Crear usuario con datos ingresados
    final usuario = Usuario(
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      nMatricula: _matriculaController.text.trim(),
    );

    // Asignar usuario al reporte parcial
    final reporteCompleto = widget.reportePrevio;
    reporteCompleto.usuario = usuario;

    // Guardar reporte completo localmente
    await agregarReporteLocal(reporteCompleto);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte realizado exitosamente')),
    );

    Navigator.of(
      context,
    ).popUntil((route) => route.isFirst); // Regresa a pantalla principal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos personales')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese su correo';
                  if (!v.endsWith('@udec.cl')) return 'Debe usar correo UdeC';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Número de matrícula',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese su número de matrícula';
                  if (v.length != 10) return 'Ingrese su número de matrícula correctamente';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _finalizarReporte,
                icon: const Icon(Icons.save),
                label: const Text('Finalizar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
