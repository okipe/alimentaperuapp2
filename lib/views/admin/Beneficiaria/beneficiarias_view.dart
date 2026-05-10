import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GestionBeneficiariasView extends StatelessWidget {
  const GestionBeneficiariasView({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta de Colores Alimenta Perú
    const Color darkGreen = Color(0xFF1A4D2E);
    const Color bgColor = Color(0xFFF0F4F1);
    const Color accentPadron = Color(0xFF2E7D52);
    const Color accentDonaciones = Color(0xFFD65A5A);
    const Color accentCocinera = Color(0xFF3B82C4);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER SUPERIOR ---
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
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Text(
                          "Gestión Social",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Beneficiarias y Colaboradores",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Administración de la comunidad",
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- LISTA DE OPERACIONES ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OPERACIONES DISPONIBLES",
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: darkGreen.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildActionCard(
                    context,
                    title: "Padrón General",
                    subtitle: "Registro y lista de comensales",
                    icon: Icons.assignment_ind_rounded,
                    accentColor: accentPadron,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: accentPadron,
                    route: '/padron_lista',
                  ),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    title: "Control de Donaciones",
                    subtitle: "Validación de ingresos y productos",
                    icon: Icons.volunteer_activism_rounded,
                    accentColor: accentDonaciones,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: accentDonaciones,
                    route: '/gestion_donaciones',
                  ),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    title: "Personal de Cocina",
                    subtitle: "Gestión de cocineras y roles",
                    icon: Icons.soup_kitchen_rounded,
                    accentColor: accentCocinera,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: accentCocinera,
                    route: '/registro_cocinera',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color iconBg,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
              ),
              // CORRECCIÓN AQUÍ: Se cambió Expanded por Padding
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                color: const Color(0xFF7A9E8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF3B7A57),
                      ),
                    ],
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
