import 'package:flutter/material.dart';
import 'package:objetos_perdidos/detalle_reporte.dart';
import 'package:objetos_perdidos/input_validator.dart';
import 'package:objetos_perdidos/reporte.dart';
import 'package:objetos_perdidos/usuario.dart';
import 'algoritmo_service.dart';

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

    await CoincidenciaService.detectarCoincidenciasParaNuevoReporte(reporteCompleto);

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
      appBar: AppBar(
        title: const Text(
          'Datos personales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Información del usuario",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              // ===== NOMBRE =====
              Text(
                "Nombre completo *",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: "Ej: Juan Pérez",
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: InputValidator.validateName,
              ),

              const SizedBox(height: 20),

              // ===== CORREO =====
              Text(
                "Correo institucional *",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "usuario@udec.cl",
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: InputValidator.validateUdecEmail,
              ),

              const SizedBox(height: 20),

              // ===== MATRÍCULA =====
              Text(
                "Número de matrícula *",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _matriculaController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: "Ej: 2023123456",
                  filled: true,
                  fillColor: Colors.grey[100],
                  counterText: "",
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: InputValidator.validateMatricula,
              ),

              const SizedBox(height: 30),

              // ===== BOTÓN FINALIZAR =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _finalizarReporte,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Finalizar reporte',
                    style: TextStyle(fontSize: 16),
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
