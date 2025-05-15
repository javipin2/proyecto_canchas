//reserva models
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'cancha.dart';
import 'horario.dart';
import 'package:flutter/material.dart';

enum TipoAbono { parcial, completo }

class Reserva {
  String id;
  Cancha cancha;
  DateTime fecha;
  Horario horario;
  String sede;
  TipoAbono tipoAbono;
  double montoTotal;
  double montoPagado;
  String? nombre;
  String? telefono;
  String? email;
  bool confirmada;

  Reserva({
    required this.id,
    required this.cancha,
    required this.fecha,
    required this.horario,
    required this.sede,
    required this.tipoAbono,
    required this.montoTotal,
    required this.montoPagado,
    this.nombre,
    this.telefono,
    this.email,
    this.confirmada = false,
  });

  factory Reserva.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Reserva(
      id: doc.id,
      cancha: Cancha.fromFirestore(doc),
      fecha: DateFormat('yyyy-MM-dd').parse(data['fecha']),
      horario: Horario(
          hora: TimeOfDay(
              hour: int.parse(data['horario'].split(':')[0]), minute: 0)),
      sede: data['sede'] ?? '',
      tipoAbono:
          data['estado'] == 'completo' ? TipoAbono.completo : TipoAbono.parcial,
      montoTotal: (data['valor'] ?? 0).toDouble(),
      montoPagado: (data['montoPagado'] ?? 0).toDouble(),
      nombre: data['nombre'],
      telefono: data['telefono'],
      email: data['correo'],
      confirmada: data['confirmada'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'correo': email,
      'fecha': DateFormat('yyyy-MM-dd').format(fecha),
      'cancha_id': cancha.id,
      'horario': horario.horaFormateada,
      'estado': tipoAbono == TipoAbono.completo ? 'completo' : 'parcial',
      'valor': montoTotal,
      'montoPagado': montoPagado,
      'sede': sede,
      'confirmada': confirmada,
      'created_at': Timestamp.now(),
    };
  }
}
