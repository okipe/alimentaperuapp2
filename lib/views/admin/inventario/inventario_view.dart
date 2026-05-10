import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventarioView extends StatelessWidget {
  const InventarioView({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta de Colores Alimenta Perú
    const Color darkGreen = Color(0xFF1A4D2E);
    const Color bgColor = Color(0xFFF0F4F1);
    const Color accentRed = Color(0xFFD65A5A); // Rojo para Salidas
    const Color accentBlue = Color(0xFF3B82C4);
    const Color accentGreen = Color(0xFF2E7D52);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── HEADER PREMIUM CON CÍRCULOS ──
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 40,
                  left: 22,
                  right: 22,
                ),
                decoration: const BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "ALMACÉN CENTRAL",
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Gestión de Inventario",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),

          // ── CUERPO: TARJETAS DE OPERACIÓN ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERACIONES DE CONTROL',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF7A9E8A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInventoryCard(
                    context,
                    title: "Consulta de Stock",
                    subtitle: "Visualizar existencias actuales",
                    icon: Icons.inventory_2_rounded,
                    accentColor: accentBlue,
                    iconBg: const Color(0xFFE3F0FF),
                    iconColor: const Color(0xFF1C5FA8),
                    route: '/reporte_stock',
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryCard(
                    context,
                    title: "Registrar Ingresos",
                    subtitle: "Entrada de nuevos insumos",
                    icon: Icons.add_box_rounded,
                    accentColor: accentGreen,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: accentGreen,
                    route: '/registro_ingreso',
                  ),
                  const SizedBox(height: 16),
                  // REGISTRO DE SALIDA EN ROJO
                  _buildInventoryCard(
                    context,
                    title: "Registrar Salidas",
                    subtitle: "Despacho de raciones diarias",
                    icon: Icons.unarchive_rounded,
                    accentColor: accentRed,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: accentRed,
                    route: '/registro_salida',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color iconBg,
    required Color iconColor,
    required String route,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFBDDAC8).withOpacity(0.4)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 26, color: iconColor),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C3326),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7A9E8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accentColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
