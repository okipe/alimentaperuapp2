import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<String?> iniciarSesion(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Autenticamos al usuario
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Buscamos su rol en Firestore
      if (userCredential.user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          // Retornamos el rol exacto de tu base de datos
          String rol = data['rol'] ?? 'comensal';

          _isLoading = false;
          notifyListeners();
          return rol;
        } else {
          _errorMessage = 'Usuario no encontrado en la base de datos.';
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        _errorMessage = 'No hay un usuario con ese correo.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Contraseña incorrecta.';
      } else {
        _errorMessage = 'Error de autenticación: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }
}
