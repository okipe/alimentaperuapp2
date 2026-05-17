import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alimentaperu_app/viewmodels/menu_diario_viewmodel.dart';

class MenuDiarioView extends StatefulWidget {
  const MenuDiarioView({super.key});

  @override
  State<MenuDiarioView> createState() => _MenuDiarioViewState();
}

class _MenuDiarioViewState extends State<MenuDiarioView> {
  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF2E7D32);

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
      // 1. Guardamos en el documento del usuario para el control de límites de raciones
      await userRef.set({
        'conteoReservas': racionesHoy + 1,
        'fechaUltimaReserva': hoy,
      }, SetOptions(merge: true));

      // 2. NUEVO: Registramos la reserva de manera independiente con su respectiva información
      await userRef.collection('historial_reservas').add({
        'fecha': hoy,
        'menu': menuVM.platoPrincipal,
        'cantidad': 1, // Se registra una ración por cada pulsación exitosa
        'timestamp': FieldValue.serverTimestamp(),
      });

      _notificar("✅ ¡Reserva confirmada!", Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuVM = Provider.of<MenuDiarioViewModel>(context);
    final user = FirebaseAuth.instance.currentUser;

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
                                color: Colors.black.withValues(alpha: 0.05),
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
                              shadowColor: accentGreen.withValues(alpha: 0.4),
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

                        // --- SECCIÓN AÑADIDA: HISTORIAL DE RESERVAS ---
                        const SizedBox(height: 40),
                        if (user != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.bookmark_added,
                                color: primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Mis Reservas de Hoy",
                                style: GoogleFonts.urbanist(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2D3436),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(user.uid)
                                .collection('historial_reservas')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: LinearProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Aún no cuentas con reservas registradas.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.urbanist(
                                      color: Colors.grey[500],
                                      fontSize: 15,
                                    ),
                                  ),
                                );
                              }

                              final reservas = snapshot.data!.docs;

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reservas.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item =
                                      reservas[index].data()
                                          as Map<String, dynamic>;
                                  final String fecha = item['fecha'] ?? '';
                                  final String menu = item['menu'] ?? 'Menú';
                                  final int cantidad = item['cantidad'] ?? 1;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.02,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              menu.toUpperCase(),
                                              style: GoogleFonts.urbanist(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: const Color(0xFF2D3436),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Fecha: $fecha",
                                              style: GoogleFonts.urbanist(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryGreen.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            "$cantidad Ración(es)",
                                            style: GoogleFonts.urbanist(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
