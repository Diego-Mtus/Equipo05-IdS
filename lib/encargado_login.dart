import 'package:flutter/material.dart';
import 'package:objetos_perdidos/menu_reportes.dart';

class EncargadoLoginScreen extends StatefulWidget {
  const EncargadoLoginScreen({super.key});

  @override
  State<EncargadoLoginScreen> createState() => _EncargadoLoginScreenState();
}

class _EncargadoLoginScreenState extends State<EncargadoLoginScreen> {
  bool _loggedIn = false;

  void _iniciarSesion() {
    setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso Encargado'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Encargado', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 18),

                  if (!_loggedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _iniciarSesion,
                        child: const Text('Iniciar sesión'),
                      ),
                    ),
                  ] else ...[
                    const Text('Sesión iniciada como Encargado', textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list),
                        label: const Text('Ver reportes'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportesScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Ver coincidencias'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            // Reemplazar con la pantalla de coincidencias cuando esté disponible
                            MaterialPageRoute(builder: (_) => const ReportesScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _loggedIn = false),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}