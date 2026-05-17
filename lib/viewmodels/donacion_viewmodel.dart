import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonacionViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> registrarDonacion({
    required String productoNombre,
    required num cantidadDonada,
    required String unidad,
    required String categoria,
    required DateTime fechaVencimiento,
  }) async {
    try {
      String uid = _auth.currentUser?.uid ?? "anonimo";
      await _firestore.collection('Donaciones').add({
        'donanteID': uid,
        'producto': productoNombre,
        'cantidad': cantidadDonada,
        'unidad': unidad,
        'categoria': categoria,
        'fecha_vencimiento': Timestamp.fromDate(fechaVencimiento),
        'fecha_registro': FieldValue.serverTimestamp(),
        'estado': 'Pendiente',
      });
      return true;
    } catch (e) {
      debugPrint("Error al registrar: $e");
      return false;
    }
  }
}
