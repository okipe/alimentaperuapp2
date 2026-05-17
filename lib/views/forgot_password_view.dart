import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    // 1. Validar el formulario antes de empezar
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 2. Intento de enviar el correo de recuperación
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // 3. Si todo sale bien y la pantalla sigue abierta, mostrar éxito
      if (mounted) {
        _mostrarExito();
      }
    } on FirebaseAuthException catch (e) {
      // 4. Manejo de errores específicos de Firebase
      String mensaje = "Error al enviar el correo";

      if (e.code == 'user-not-found') {
        mensaje = "Este correo no está registrado";
      } else if (e.code == 'invalid-email') {
        mensaje = "El formato del correo no es válido";
      }

      // 5. IMPORTANTE: Validar mounted antes de usar el context en el catch
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Manejo de cualquier otro error inesperado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ocurrió un error inesperado"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      // 6. Quitar el estado de carga solo si la pantalla sigue activa
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Correo Enviado",
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Revisa tu bandeja de entrada para restablecer tu clave.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Vuelve al login
            },
            child: const Text("VOLVER"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text("Recuperar Clave", style: GoogleFonts.urbanist()),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Color(0xFF1B5E20)),
              const SizedBox(height: 20),
              Text(
                "Ingresa tu correo para recibir el enlace de recuperación",
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Ingresa tu correo" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENVIAR CORREO",
                          style: TextStyle(color: Colors.white),
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
