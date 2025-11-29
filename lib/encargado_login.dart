import 'package:flutter/material.dart';

class EncargadoLoginScreen extends StatefulWidget {
  const EncargadoLoginScreen({super.key});

  @override
  State<EncargadoLoginScreen> createState() => _EncargadoLoginScreenState();
}

class _EncargadoLoginScreenState extends State<EncargadoLoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso Encargado'),
        centerTitle: true,
      ),
  
    );
  }
}