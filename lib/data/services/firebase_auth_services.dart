import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Iniciar sesión con correo y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Error en el login: $e");
      return null;
    }
  }

  // Obtener los datos del usuario desde la colección 'Login'
  Future<UsuarioModel?> getUsuarioData(String uid) async {
    try {
      // Usamos la colección 'Login' que configuraste manualmente
      DocumentSnapshot doc = await _firestore
          .collection('Login')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UsuarioModel.fromFirestore(doc);
      }
    } catch (e) {
      print("Error obteniendo datos: $e");
    }
    return null;
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
