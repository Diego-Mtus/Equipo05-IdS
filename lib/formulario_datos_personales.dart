import 'package:flutter/material.dart';
import 'package:objetos_perdidos/detalle_reporte.dart';
import 'package:objetos_perdidos/input_validator.dart';
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

    final reportes = await obtenerReportesLocales();

    for (Reporte r in reportes) print(r.descripcion);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleReporteScreen(reporte: reporteCompleto),
        ),
      );
    }
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
              // CAMPO NOMBRE
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),

                validator: InputValidator.validateName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: 16),

              // CAMPO CORREO
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: InputValidator.validateUdecEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: 16),

              // CAMPO MATRÍCULA
              TextFormField(
                controller: _matriculaController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Número de matrícula',
                  border: OutlineInputBorder(),
                  counterText: "",
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: InputValidator.validateMatricula,
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
