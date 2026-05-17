import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PadronBeneficiariosView extends StatefulWidget {
  const PadronBeneficiariosView({super.key});

  @override
  State<PadronBeneficiariosView> createState() =>
      _PadronBeneficiariosViewState();
}

class _PadronBeneficiariosViewState extends State<PadronBeneficiariosView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = "";

  // Colores Premium
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _eliminarUsuario(String docId) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Text(
              "¿Confirmar eliminación?",
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
            content: const Text("El registro se borrará permanentemente."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("CANCELAR"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "ELIMINAR",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmar) {
      await _firestore.collection('usuarios').doc(docId).delete();
      _mostrarSnackBar("Registro eliminado", Colors.black87);
    }
  }

  Future<void> _guardarDatos({String? docId}) async {
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final dni = _dniCtrl.text.trim();

    if (nombre.isEmpty || apellido.isEmpty || dni.isEmpty) {
      _mostrarSnackBar("⚠️ Complete todos los campos", Colors.orange.shade800);
      return;
    }

    if (dni.length != 8) {
      _mostrarSnackBar("⚠️ El DNI debe tener 8 dígitos", Colors.redAccent);
      return;
    }

    try {
      final data = {
        'nombre': nombre,
        'apellido': apellido,
        'dni': dni,
        'rol': 'comensal',
        'saldo': 0.0,
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        await _firestore.collection('usuarios').add(data);
      } else {
        await _firestore.collection('usuarios').doc(docId).update({
          'nombre': nombre,
          'apellido': apellido,
          'dni': dni,
        });
      }

      _nombreCtrl.clear();
      _apellidoCtrl.clear();
      _dniCtrl.clear();
      if (mounted) Navigator.pop(context);
      _mostrarSnackBar("✅ Operación exitosa", accentGreen);
    } catch (e) {
      _mostrarSnackBar("❌ Error de conexión", Colors.red);
    }
  }

  void _mostrarFormulario({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      _nombreCtrl.text = data['nombre'] ?? '';
      _apellidoCtrl.text = data['apellido'] ?? '';
      _dniCtrl.text = data['dni'] ?? '';
    } else {
      _nombreCtrl.clear();
      _apellidoCtrl.clear();
      _dniCtrl.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    docId == null ? "Nuevo Registro" : "Editar Registro",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInputManual(_nombreCtrl, "Nombres", Icons.person_outline),
              const SizedBox(height: 12),
              _buildInputManual(
                _apellidoCtrl,
                "Apellidos",
                Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildInputManual(
                _dniCtrl,
                "DNI",
                Icons.assignment_ind_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => _guardarDatos(docId: docId),
                  child: Text(
                    docId == null ? "REGISTRAR" : "ACTUALIZAR",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkGreen,
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header con BOTÓN DE SALIDA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BOTÓN PARA SALIR ---
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Padrón de",
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        "Beneficiarios",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search, color: Colors.white70),
                      hintText: "Buscar por nombre o DNI...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'comensal')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final n = (data['nombre'] ?? '').toString().toLowerCase();
                  final id = (data['dni'] ?? '').toString().toLowerCase();
                  return n.contains(_filtro) || id.contains(_filtro);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bgColor,
                          child: Text(
                            userData['nombre']?[0] ?? '?',
                            style: TextStyle(color: darkGreen),
                          ),
                        ),
                        title: Text(
                          "${userData['nombre']} ${userData['apellido']}",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        subtitle: Text("DNI: ${userData['dni']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () => _mostrarFormulario(
                                docId: userDoc.id,
                                data: userData,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _eliminarUsuario(userDoc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputManual(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ]
          : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darkGreen),
        filled: true,
        fillColor: bgColor.withValues(alpha: 0.4),
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
