// lib/models/cancha.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Cancha {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagen;
  final bool techada;
  final String ubicacion;
  final double precio;
  final String sede;

  Cancha({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagen,
    required this.techada,
    required this.ubicacion,
    required this.precio,
    required this.sede,
  });

  // Método para crear una Cancha desde un documento de Firestore
  factory Cancha.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Aseguramos que cada campo exista o tenga un valor predeterminado
    return Cancha(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      imagen: data['imagen'] ?? 'assets/cancha_demo.png',
      techada: data['techada'] ?? false,
      ubicacion: data['ubicacion'] ?? '',
      precio:
          (data['precio'] is num) ? (data['precio'] as num).toDouble() : 0.0,
      sede: data['sede'] ?? '',
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen': imagen,
      'techada': techada,
      'ubicacion': ubicacion,
      'precio': precio,
      'sede': sede,
    };
  }
}
