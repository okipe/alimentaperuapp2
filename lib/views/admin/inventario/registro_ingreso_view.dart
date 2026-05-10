import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RegistroIngresoView extends StatefulWidget {
  const RegistroIngresoView({super.key});
  @override
  State<RegistroIngresoView> createState() => _RegistroIngresoViewState();
}

class _RegistroIngresoViewState extends State<RegistroIngresoView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController cantCtrl = TextEditingController();
  String? catIng;
  String? prodIng;
  String unidadIng = 'kg';
  DateTime? fechaVence;

  final Map<String, List<String>> listaMaestra = {
    'Abarrotes': [
      'Arroz',
      'Azúcar',
      'Sal',
      'Aceite vegetal',
      'Fideos',
      'Huevos',
    ],
    'Menestras': ['Lenteja', 'Frejol', 'Garbanzo'],
    'Verduras': ['Papa', 'Cebolla', 'Tomate', 'Zanahoria'],
    'Carnes': ['Pollo', 'Carne de res', 'Pescado'],
  };

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER PREMIUM ---
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
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            "REGISTRO DE INGRESOS",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
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

          // --- FORMULARIO Y LÓGICA INTACTA ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("FECHA DE REGISTRO"),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: darkGreen.withOpacity(0.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("CATEGORÍA"),
                    _buildDropdown(
                      catIng,
                      listaMaestra.keys.toList(),
                      (val) => setState(() {
                        catIng = val;
                        prodIng = null;
                      }),
                    ),

                    if (catIng != null) ...[
                      const SizedBox(height: 20),
                      _buildLabel("PRODUCTO"),
                      _buildDropdown(
                        prodIng,
                        listaMaestra[catIng!]!,
                        (val) => setState(() => prodIng = val),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("CANTIDAD"),
                              TextField(
                                controller: cantCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: bgColor.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("UNIDAD"),
                              _buildDropdown(unidadIng, [
                                'kg',
                                'lt',
                                'unid',
                                'sacos',
                              ], (val) => setState(() => unidadIng = val!)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("FECHA DE VENCIMIENTO"),
                    InkWell(
                      onTap: () async {
                        DateTime? p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (p != null) setState(() => fechaVence = p);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: fechaVence == null
                                ? Colors.red.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fechaVence == null
                                  ? "Seleccionar fecha..."
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(fechaVence!),
                              style: GoogleFonts.dmSans(
                                color: fechaVence == null
                                    ? Colors.red
                                    : darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: accentGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // LÓGICA RÁPIDA: Sin "await" que congele la pantalla
                          if (prodIng != null &&
                              cantCtrl.text.isNotEmpty &&
                              fechaVence != null) {
                            // 1. Mostrar notificación inmediata
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "✅ Guardado con éxito",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Color(0xFF2E7D52),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // 2. Enviar a Firebase (ocurre en segundo plano)
                            _firestore.collection('Productos').add({
                              'nombre': prodIng,
                              'nombre_busqueda': prodIng!.toUpperCase(),
                              'categoria': catIng,
                              'cantidad': double.parse(cantCtrl.text),
                              'unidad': unidadIng,
                              'fecha_vencimiento': Timestamp.fromDate(
                                fechaVence!,
                              ),
                              'fecha_ingreso': FieldValue.serverTimestamp(),
                            });

                            // 3. Limpiar formulario inmediatamente
                            setState(() {
                              cantCtrl.clear();
                              prodIng = null;
                              catIng = null;
                              fechaVence = null;
                            });
                          } else {
                            // Alerta si faltan datos
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "⚠️ Completa todos los campos",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "GUARDAR REGISTRO",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accentGreen.withOpacity(0.7),
      ),
    ),
  );

  Widget _buildDropdown(
    String? v,
    List<String> i,
    Function(String?) onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bgColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: v,
        isExpanded: true,
        items: i
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    ),
  );
}
