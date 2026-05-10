import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistroCocineraView extends StatefulWidget {
  const RegistroCocineraView({super.key});

  @override
  State<RegistroCocineraView> createState() => _RegistroCocineraViewState();
}

class _RegistroCocineraViewState extends State<RegistroCocineraView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores para capturar el texto de los inputs
  final TextEditingController _comedorCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _edadCtrl = TextEditingController();

  // Paleta de Colores del Dashboard (Verde Premium)
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentColor = const Color(0xFF2E7D52);
  final Color textDark = const Color(0xFF1C3326);

  // --- LÓGICA DE GUARDADO ---
  Future<void> _guardarRegistro() async {
    if (_comedorCtrl.text.isEmpty ||
        _nombreCtrl.text.isEmpty ||
        _apellidoCtrl.text.isEmpty ||
        _edadCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Completa todos los campos",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Guardar en la colección 'cocineras' tal como en tu base de datos
      await _firestore.collection('cocineras').add({
        'comedor': _comedorCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      // Limpiar formulario al instante
      setState(() {
        _comedorCtrl.clear();
        _nombreCtrl.clear();
        _apellidoCtrl.clear();
        _edadCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "✅ Cocinera registrada con éxito",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Color(0xFF2E7D52),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LÓGICA DE ELIMINADO ---
  Future<void> _eliminarCocinera(String id) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Eliminar Registro",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        content: Text(
          "¿Estás seguro de eliminar a esta cocinera?",
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _firestore.collection('cocineras').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER PREMIUM (Estilo Dashboard) ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "GESTIÓN DE PERSONAL",
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Registro de Cocinera",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- CUERPO ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta del Formulario
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                          "Nombre del Comedor",
                          Icons.store_rounded,
                          _comedorCtrl,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "Nombre completo",
                          Icons.person_outline_rounded,
                          _nombreCtrl,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "Apellidos",
                          Icons.badge_outlined,
                          _apellidoCtrl,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "Edad",
                          Icons.cake_outlined,
                          _edadCtrl,
                          isNumber: true,
                        ),
                        const SizedBox(height: 25),

                        // Botón Guardar Premium
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            onPressed:
                                _guardarRegistro, // Conectado a la función
                            child: Text(
                              "GUARDAR REGISTRO",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Título de la Lista
                  Text(
                    "PERSONAL REGISTRADO",
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Lista conectada a Firebase en tiempo real
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('cocineras')
                        .orderBy('fecha_registro', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No hay personal registrado aún.",
                            style: GoogleFonts.dmSans(color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return _buildCookCard(
                            id: doc.id,
                            name: "${data['nombre']} ${data['apellido']}",
                            comedor: "Comedor: ${data['comedor']}",
                            edad: "${data['edad']} años",
                            emoji: "🌿",
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES ---

  Widget _buildInputField(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: accentColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, // Conectado al controlador
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: darkGreen.withOpacity(0.3)),
            filled: true,
            fillColor: bgColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildCookCard({
    required String id,
    required String name,
    required String comedor,
    required String edad,
    required String emoji,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comedor,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "Edad: $edad",
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed:
                    () {}, // Aquí puedes poner la lógica de edición en el futuro si lo necesitas
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () =>
                    _eliminarCocinera(id), // Lógica de borrado conectada
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
