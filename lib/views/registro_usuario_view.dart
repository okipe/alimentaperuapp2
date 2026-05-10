import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistroUsuarioView extends StatefulWidget {
  const RegistroUsuarioView({super.key});

  @override
  State<RegistroUsuarioView> createState() => _RegistroUsuarioViewState();
}

class _RegistroUsuarioViewState extends State<RegistroUsuarioView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePass = true;

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final List<String> _comedores = [
    'Comedor Santa Rosa',
    'Comedor Virgen de la Puerta',
    'Comedor San Martín',
    'Comedor Villa El Salvador',
  ];
  String? _comedorSeleccionado;

  Future<void> _ejecutarRegistro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Registro en Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      // 2. Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': _nombreCtrl.text.trim(),
            'apellido': _apellidoCtrl.text.trim(),
            'dni': _dniCtrl.text.trim(),
            'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
            'email': _emailCtrl.text.trim(),
            'comedor': _comedorSeleccionado,
            'rol': 'comensal',
            'saldo': 0.0,
            'fecha_registro': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/comensal_dashboard');
      }
    } on FirebaseAuthException catch (e) {
      _mostrarError(e.message ?? "Error al registrar");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera Profesional (Sin la X)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "UNIRSE A ALIMENTA PERÚ",
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Datos Personales"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            _nombreCtrl,
                            "Nombre",
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            _apellidoCtrl,
                            "Apellido",
                            Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Campo DNI con validación
                    _buildInput(
                      _dniCtrl,
                      "DNI (8 dígitos)",
                      Icons.badge_outlined,
                      isNumber: true,
                      isDni: true,
                    ),

                    const SizedBox(height: 15),
                    _buildInput(
                      _edadCtrl,
                      "Edad",
                      Icons.cake_outlined,
                      isNumber: true,
                    ),

                    const SizedBox(height: 25),
                    _buildLabel("Ubicación"),
                    _buildDropdown(),

                    const SizedBox(height: 25),
                    _buildLabel("Cuenta"),
                    _buildInput(
                      _emailCtrl,
                      "Correo Electrónico",
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildInput(
                      _passCtrl,
                      "Contraseña",
                      Icons.lock_outline,
                      isPass: true,
                    ),

                    const SizedBox(height: 30),

                    // Botón de Registro Principal
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _isLoading ? null : _ejecutarRegistro,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "FINALIZAR REGISTRO",
                                style: GoogleFonts.urbanist(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Separador
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "O también",
                            style: GoogleFonts.urbanist(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botón de Google Corregido (Sin errores de carga ni overflow)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.redAccent,
                        ),
                        label: Text(
                          "Registrarse con Google",
                          style: GoogleFonts.urbanist(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          _mostrarError(
                            "Configura Google SignIn en Firebase para activar.",
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Volver al login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Ya tienes una cuenta?",
                          style: GoogleFonts.urbanist(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            "Inicia sesión",
                            style: GoogleFonts.urbanist(
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 5),
    child: Text(
      text,
      style: GoogleFonts.urbanist(
        fontWeight: FontWeight.bold,
        color: Colors.green[900],
      ),
    ),
  );

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool isNumber = false,
    bool isDni = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass ? _obscurePass : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isNumber) FilteringTextInputFormatter.digitsOnly,
        if (isDni) LengthLimitingTextInputFormatter(8),
      ],
      style: GoogleFonts.urbanist(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF639922), size: 20),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Obligatorio";
        if (isDni && v.length != 8) return "DNI de 8 dígitos";
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.storefront,
          color: Color(0xFF639922),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(
        "Selecciona tu comedor",
        style: GoogleFonts.urbanist(fontSize: 14),
      ),
      initialValue: _comedorSeleccionado,
      items: _comedores
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: GoogleFonts.urbanist(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _comedorSeleccionado = val),
      validator: (v) => v == null ? "Selecciona un local" : null,
    );
  }
}
