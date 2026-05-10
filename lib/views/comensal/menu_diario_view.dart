import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alimentaperu_app/viewmodels/menu_diario_viewmodel.dart';
import 'package:alimentaperu_app/viewmodels/ia_service.dart';

class MenuDiarioView extends StatefulWidget {
  const MenuDiarioView({super.key});

  @override
  State<MenuDiarioView> createState() => _MenuDiarioViewState();
}

class _MenuDiarioViewState extends State<MenuDiarioView> {
  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF2E7D32);

  // Notificación ultra-rápida (1 segundo)
  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  // Confirmación instantánea antes de reservar
  Future<void> _intentarReserva(MenuDiarioViewModel menuVM) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("¿Confirmar Reserva?", textAlign: TextAlign.center),
        content: const Text(
          "Se reservará una ración de tu límite diario de hoy.",
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "SÍ, RESERVAR",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String hoy = DateTime.now().toString().substring(0, 10);
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);

    final userDoc = await userRef.get();
    int racionesHoy = 0;

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      if (data['fechaUltimaReserva'] == hoy) {
        racionesHoy = data['conteoReservas'] ?? 0;
      }
    }

    if (racionesHoy >= 2) {
      _notificar("⚠️ Límite diario alcanzado (2/2)", Colors.orange);
      return;
    }

    bool exito = await menuVM.reservarRacion();
    if (exito) {
      await userRef.set({
        'conteoReservas': racionesHoy + 1,
        'fechaUltimaReserva': hoy,
      }, SetOptions(merge: true));
      _notificar("✅ ¡Reserva confirmada!", Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuVM = Provider.of<MenuDiarioViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(
          "ALIMENTA PERÚ",
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: menuVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                  ),
                  Padding(
                    // 🛡️ CORRECCIÓN PANTALLA ROJA: Se cambió el padding negativo a 10 positivo
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.restaurant_menu,
                                size: 50,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                menuVM.platoPrincipal.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.urbanist(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2D3436),
                                ),
                              ),
                              const Divider(height: 40, thickness: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 🛡️ CORRECCIÓN ÍCONO: Se cambió 'some_count_icon' por 'Icons.groups'
                                  const Icon(
                                    Icons.groups,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Quedan ${menuVM.racionesDisponibles} raciones",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  "VER ANÁLISIS NUTRICIONAL",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    _invocarIA(menuVM.platoPrincipal),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              elevation: 8,
                              shadowColor: accentGreen.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            onPressed: menuVM.racionesDisponibles > 0
                                ? () => _intentarReserva(menuVM)
                                : null,
                            child: Text(
                              menuVM.racionesDisponibles > 0
                                  ? "RESERVAR MI RACIÓN"
                                  : "PLATO AGOTADO",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _invocarIA(String plato) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    String res = await IAService.obtenerInfoNutricional(plato);
    if (!mounted) return;
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Nutri-IA 🥗",
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              res,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
