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

  // Lista Maestra Unificada
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
          _buildHeader(),

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
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("FECHA DE RECEPCIÓN"),
                    _buildReadOnlyDate(),
                    const SizedBox(height: 20),

                    _buildLabel("CATEGORÍA"),
                    _buildDropdown(catIng, listaMaestra.keys.toList(), (val) {
                      setState(() {
                        catIng = val;
                        prodIng = null;
                      });
                    }),

                    if (catIng != null) ...[
                      const SizedBox(height: 20),
                      _buildLabel("PRODUCTO"),
                      _buildDropdown(prodIng, listaMaestra[catIng!]!, (val) {
                        setState(() => prodIng = val);
                      }),
                    ],
                    const SizedBox(height: 20),

                    _buildCantidadUnidadRow(),
                    const SizedBox(height: 20),

                    _buildLabel("FECHA DE VENCIMIENTO (CRÍTICO PARA FIFO)"),
                    _buildDatePicker(),
                    const SizedBox(height: 35),

                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildHeader() => Stack(
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
        child: Row(
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
                "INGRESO DE PRODUCTOS",
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
      ),
    ],
  );

  Widget _buildReadOnlyDate() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: bgColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 20,
          color: darkGreen.withValues(alpha: 0.5),
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
  );

  Widget _buildCantidadUnidadRow() => Row(
    children: [
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("CANTIDAD"),
            TextField(
              controller: cantCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: bgColor.withValues(alpha: 0.5),
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
  );

  Widget _buildDatePicker() => InkWell(
    onTap: () async {
      DateTime? p = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 30)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (p != null) setState(() => fechaVence = p);
    },
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fechaVence == null
            ? const Color(0xFFFFF1F1)
            : bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fechaVence == null
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fechaVence == null
                ? "Seleccionar fecha..."
                : DateFormat('dd/MM/yyyy').format(fechaVence!),
            style: GoogleFonts.dmSans(
              color: fechaVence == null ? Colors.red : darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            Icons.calendar_today_rounded,
            color: fechaVence == null ? Colors.red : accentGreen,
            size: 20,
          ),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      onPressed: () {
        if (prodIng != null && cantCtrl.text.isNotEmpty && fechaVence != null) {
          // 1. NOTIFICACIÓN E INTERFAZ INSTANTÁNEA
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "✅ Lote registrado con éxito",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Color(0xFF2E7D52),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Captura de datos para el proceso asíncrono
          final String pName = prodIng!;
          final String cName = catIng!;
          final double quantity = double.parse(cantCtrl.text);
          final String unit = unidadIng;
          final DateTime expiry = fechaVence!;

          // 2. PROCESO EN SEGUNDO PLANO (Firebase)
          _firestore.collection('Productos').add({
            'nombre': pName,
            'nombre_busqueda': pName.toUpperCase(), // Clave para búsqueda FIFO
            'categoria': cName,
            'cantidad': quantity,
            'unidad': unit,
            'fecha_vencimiento': Timestamp.fromDate(expiry),
            'fecha_ingreso': FieldValue.serverTimestamp(),
          });

          // 3. LIMPIEZA INMEDIATA
          setState(() {
            cantCtrl.clear();
            prodIng = null;
            catIng = null;
            fechaVence = null;
          });
        } else {
          _showErrorSnackBar("⚠️ Por favor, completa todos los campos");
        }
      },
      child: Text(
        "GUARDAR PRODUCTO",
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
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
        color: accentGreen.withValues(alpha: 0.7),
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
      color: bgColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        initialValue: v,
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
