import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GestionBeneficiariasView extends StatelessWidget {
  const GestionBeneficiariasView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A4D2E);
    const Color bgColor = Color(0xFFF0F4F1);
    const Color accentSaldos = Color(0xFFE8924A);
    const Color accentCocinera = Color(0xFF3B82C4);
    const Color accentPadron = Color(0xFF2E7D52);
    const Color accentDonaciones = Color(0xFFD65A5A); // Color solidario añadido

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
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
                          "ADMINISTRACIÓN",
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
                      "Gestión Principal", // Cambiado para abarcar todo
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
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERACIONES DISPONIBLES',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF7A9E8A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // MÓDULO 1
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

                  // MÓDULO 2
                  _buildActionCard(
                    context,
                    title: "Control de Saldos",
                    subtitle: "Validación de recargas pendientes",
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: accentSaldos,
                    iconBg: const Color(0xFFFFF0E4),
                    iconColor: const Color(0xFFC86A1A),
                    route: '/gestion_saldos',
                  ),
                  const SizedBox(height: 16),

                  // MÓDULO 3 (NUEVO CONTROL DE DONACIONES)
                  _buildActionCard(
                    context,
                    title: "Control de Donaciones",
                    subtitle: "Validación de ingresos y productos",
                    icon: Icons.volunteer_activism_rounded,
                    accentColor: accentDonaciones,
                    iconBg: const Color(0xFFFCEAEA),
                    iconColor: const Color(0xFFB73D3D),
                    route:
                        '/gestion_donaciones', // Asegúrate de registrar esta ruta en tu main.dart
                  ),
                  const SizedBox(height: 16),

                  // MÓDULO 4
                  _buildActionCard(
                    context,
                    title: "Personal de Cocina",
                    subtitle: "Gestión de cocineras por comedor",
                    icon: Icons.restaurant_menu_rounded,
                    accentColor: accentCocinera,
                    iconBg: const Color(0xFFE3F0FF),
                    iconColor: const Color(0xFF1C5FA8),
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
            ],
          ),
        ),
      ),
    );
  }
}
