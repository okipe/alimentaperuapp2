import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alimentaperu_app/viewmodels/menu_diario_viewmodel.dart';
import 'package:alimentaperu_app/viewmodels/estado_pagos_viewmodel.dart';

class MenuDiarioView extends StatefulWidget {
  const MenuDiarioView({Key? key}) : super(key: key);

  @override
  State<MenuDiarioView> createState() => _MenuDiarioViewState();
}

class _MenuDiarioViewState extends State<MenuDiarioView> {
  final double _costoMenu = 5.00;

  // Lógica combinada: Pagar + Reservar + Límite de 2 por día
  Future<void> _procesarReservaConPago(
    BuildContext context,
    MenuDiarioViewModel menuVM,
    double saldoActual,
  ) async {
    if (saldoActual < _costoMenu) {
      _mostrarError("Saldo insuficiente. Por favor, recarga tu cuenta.");
      return;
    }

    if (menuVM.racionesDisponibles <= 0) {
      _mostrarError("Lo sentimos, ya no quedan raciones disponibles hoy.");
      return;
    }

    // --- VALIDACIÓN: MÁXIMO 2 RESERVAS POR DÍA ---
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    int nuevoConteo = 1; // Por defecto es 1 si es su primera reserva del día

    if (userId != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          if (data.containsKey('fecha_ultima_reserva') &&
              data['fecha_ultima_reserva'] != null) {
            DateTime ultimaReserva = (data['fecha_ultima_reserva'] as Timestamp)
                .toDate();
            DateTime hoy = DateTime.now();

            // Si la última reserva fue el mismo día de hoy
            if (ultimaReserva.year == hoy.year &&
                ultimaReserva.month == hoy.month &&
                ultimaReserva.day == hoy.day) {
              int reservasHoy = data.containsKey('reservas_hoy')
                  ? data['reservas_hoy']
                  : 1;

              // Validamos si ya alcanzó el límite de 2
              if (reservasHoy >= 2) {
                _mostrarError(
                  "⚠️ Has alcanzado el límite máximo de 2 reservas por día.",
                );
                return; // Bloquea la continuación
              } else {
                nuevoConteo =
                    reservasHoy +
                    1; // Incrementa el contador para el guardado final
              }
            } else {
              // Es un día nuevo, el conteo se reinicia a 1
              nuevoConteo = 1;
            }
          }
        }
      } catch (e) {
        _mostrarError("Error al verificar tu historial. Intenta nuevamente.");
        return;
      }
    }
    // ----------------------------------------------------

    // 1. Mostrar diálogo de confirmación premium
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DialogoConfirmacion(plato: menuVM.platoPrincipal, costo: _costoMenu),
    );

    if (confirmar != true) return;

    final pagosVM = Provider.of<EstadoPagosViewModel>(context, listen: false);

    // 2. Ejecutar el cobro en la billetera
    bool pagoExitoso = await pagosVM.pagarCuotaSemanal(
      _costoMenu,
      "Menú: ${menuVM.platoPrincipal}",
    );

    // 3. Si el pago fue exitoso, reservamos la ración en la base de datos
    if (pagoExitoso) {
      bool reservaExitosa = await menuVM.reservarRacion();

      if (reservaExitosa && mounted) {
        // Guardamos la marca de tiempo de HOY y actualizamos el contador en el perfil del usuario
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .update({
                'fecha_ultima_reserva': FieldValue.serverTimestamp(),
                'reservas_hoy': nuevoConteo,
              });
        }
        _mostrarExito(
          "¡Ración reservada! Se han descontado S/ 5.00 de tu saldo.",
        );
      } else {
        _mostrarError(
          "Hubo un error al separar tu plato. Contacta a administración.",
        );
      }
    } else {
      _mostrarError(
        pagosVM.errorMessage.isNotEmpty
            ? pagosVM.errorMessage
            : "Error al procesar el pago.",
      );
    }
  }

  // --- NOTIFICACIONES RÁPIDAS (2 SEGUNDOS) ---
  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2), // Ocultar rápido
      ),
    );
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2), // Ocultar rápido
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuVM = Provider.of<MenuDiarioViewModel>(context);
    final pagosVM = Provider.of<EstadoPagosViewModel>(context);

    bool hayPlato =
        menuVM.platoPrincipal != 'No hay platos registrados hoy' &&
        !menuVM.platoPrincipal.contains('Error');
    bool hayRaciones = menuVM.racionesDisponibles > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: CustomScrollView(
        slivers: [
          // --- CABECERA ESTILO APP DE DELIVERY ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Reserva tu Ración",
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1B5E20), Colors.green[700]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // --- SECCIÓN 1: BILLETERA / SALDO ACTUAL ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: pagosVM.getStreamUsuario(),
                    builder: (context, snapshot) {
                      double saldoActual = 0.0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        saldoActual = (snapshot.data!.get('saldo') ?? 0)
                            .toDouble();
                      }
                      bool puedePagar = saldoActual >= _costoMenu;

                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tu Saldo Disponible",
                                      style: GoogleFonts.urbanist(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "S/ ${saldoActual.toStringAsFixed(2)}",
                                      style: GoogleFonts.urbanist(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: const Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!puedePagar)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Saldo Bajo",
                                  style: GoogleFonts.urbanist(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  Text(
                    "MENÚ DEL DÍA",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- SECCIÓN 2: TARJETA DEL PLATO ---
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Imagen o Ícono ilustrativo
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'food_icon',
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  size: 50,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.deepOrange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Plato Principal",
                                      style: GoogleFonts.urbanist(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Nombre del plato
                              Text(
                                hayPlato
                                    ? menuVM.platoPrincipal.toUpperCase()
                                    : "ESPERANDO MENÚ...",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.urbanist(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 15),

                              // Disponibilidad
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Raciones Disponibles: ",
                                    style: GoogleFonts.urbanist(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    hayPlato
                                        ? "${menuVM.racionesDisponibles}"
                                        : "0",
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          !hayPlato ||
                                              menuVM.racionesDisponibles <= 0
                                          ? Colors.red
                                          : (menuVM.racionesDisponibles > 5
                                                ? Colors.green[700]
                                                : Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // --- SECCIÓN 3: BOTÓN DE PAGO Y RESERVA ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: pagosVM.getStreamUsuario(),
                    builder: (context, snapshot) {
                      double saldoActual =
                          snapshot.hasData && snapshot.data!.exists
                          ? (snapshot.data!.get('saldo') ?? 0).toDouble()
                          : 0.0;
                      bool puedePagar = saldoActual >= _costoMenu;
                      bool botonActivo =
                          hayPlato &&
                          hayRaciones &&
                          !menuVM.isLoading &&
                          !pagosVM.isLoading;

                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: botonActivo
                                ? const Color(0xFF1B5E20)
                                : Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: botonActivo ? 5 : 0,
                            shadowColor: Colors.green.withOpacity(0.5),
                          ),
                          onPressed: botonActivo
                              ? () => _procesarReservaConPago(
                                  context,
                                  menuVM,
                                  saldoActual,
                                )
                              : null,
                          child: menuVM.isLoading || pagosVM.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      puedePagar
                                          ? Icons.shopping_bag_rounded
                                          : Icons
                                                .account_balance_wallet_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      puedePagar
                                          ? "RESERVAR POR S/ 5.00"
                                          : "SALDO INSUFICIENTE",
                                      style: GoogleFonts.urbanist(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Comedor Alimenta Perú - Villa El Salvador",
                    style: GoogleFonts.urbanist(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGET INTERNO: DIÁLOGO DE CONFIRMACIÓN PREMIUM
// ==============================================================================
class _DialogoConfirmacion extends StatelessWidget {
  final String plato;
  final double costo;

  const _DialogoConfirmacion({required this.plato, required this.costo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.orange,
                size: 35,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Confirmar Reserva",
              style: GoogleFonts.urbanist(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Estás a punto de reservar tu menú de hoy. Se descontará el costo de tu saldo virtual.",
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Plato:",
                        style: GoogleFonts.urbanist(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          plato,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total a pagar:",
                        style: GoogleFonts.urbanist(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "S/ ${costo.toStringAsFixed(2)}",
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      "Cancelar",
                      style: GoogleFonts.urbanist(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      "CONFIRMAR",
                      style: GoogleFonts.urbanist(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
