import 'package:flutter/material.dart';

class GraficasScreen extends StatelessWidget {
  const GraficasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección de Gráficas"),
      ),
      body: const Center(
        child: Text(
          "Bienvenido a la sección de gráficas.\nAquí podrás visualizar los datos próximamente.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
