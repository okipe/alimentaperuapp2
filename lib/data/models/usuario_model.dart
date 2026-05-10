import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nombre;
  final String dni;
  final String email;
  final String rol;
  final String estado;
  final DateTime fechaRegistro;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.email,
    required this.rol,
    required this.estado,
    required this.fechaRegistro,
  });

  // Este es el método "factory" que falta y causa el error en tu servicio
  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      dni: data['dni'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'BENEFICIARIA',
      estado: data['estado'] ?? 'ACTIVO',
      // Convertimos el Timestamp de Firebase a DateTime de Dart
      fechaRegistro: (data['fecha_registro'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'dni': dni,
      'email': email,
      'rol': rol,
      'estado': estado,
      'fecha_registro': Timestamp.fromDate(fechaRegistro),
    };
  }
}
