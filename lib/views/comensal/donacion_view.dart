import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DonacionView extends StatefulWidget {
  const DonacionView({super.key});

  @override
  State<DonacionView> createState() => _DonacionViewState();
}

class _DonacionViewState extends State<DonacionView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  bool _isSaving = false;
  String? _catSeleccionada;
  String? _prodSeleccionado;
  String _unidadSeleccionada = 'kg';
  DateTime? _fechaVencimiento;
  final TextEditingController _cantCtrl = TextEditingController();

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

  Future<void> _ejecutarGuardado() async {
    if (_prodSeleccionado == null ||
        _cantCtrl.text.isEmpty ||
        _fechaVencimiento == null) {
      _notificar("Por favor, completa todos los campos", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // 🔥 MODO PRO: 'Donaciones' (D mayúscula) y 'Pendiente' (P mayúscula)
      await _firestore.collection('Donaciones').add({
        'usuario_id': user?.uid,
        'nombre_donante': user?.displayName ?? "Comensal",
        'categoria': _catSeleccionada,
        'producto': _prodSeleccionado,
        'unidad': _unidadSeleccionada,
        'cantidad': double.tryParse(_cantCtrl.text) ?? 0.0,
        'fecha_vencimiento': Timestamp.fromDate(_fechaVencimiento!),
        'fecha_registro': FieldValue.serverTimestamp(),
        'estado': 'Pendiente', // Sincronizado exacto
      });

      _mostrarExito();
    } catch (e) {
      _notificar("❌ Error al registrar la donación", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _notificar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              "¡Donación Enviada!",
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tu aporte será validado por la encargada.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                "ENTENDIDO",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "DONAR PRODUCTOS",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkGreen,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardFormulario(),
            const SizedBox(height: 30),
            _buildBotonGuardar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFormulario() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("CATEGORÍA"),
          _dropdown(
            _catSeleccionada,
            listaMaestra.keys.toList(),
            "Seleccione Categoría",
            (val) => setState(() {
              _catSeleccionada = val;
              _prodSeleccionado = null;
            }),
          ),
          const SizedBox(height: 15),
          _label("PRODUCTO"),
          _dropdown(
            _prodSeleccionado,
            _catSeleccionada == null ? [] : listaMaestra[_catSeleccionada]!,
            "Seleccione Producto",
            (val) => setState(() => _prodSeleccionado = val),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("UNIDAD"),
                    _dropdown(
                      _unidadSeleccionada,
                      ['kg', 'lts', 'und'],
                      "Unid",
                      (val) => setState(() => _unidadSeleccionada = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("CANTIDAD"),
                    TextField(
                      controller: _cantCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "0.0",
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _label("FECHA DE VENCIMIENTO"),
          _buildDatePicker(),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5, left: 5),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accentGreen,
      ),
    ),
  );
  Widget _dropdown(
    String? val,
    List<String> items,
    String hint,
    Function(String?) onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: val,
        hint: Text(hint),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
  Widget _buildDatePicker() => InkWell(
    onTap: () async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (picked != null) setState(() => _fechaVencimiento = picked);
    },
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: darkGreen),
          const SizedBox(width: 10),
          Text(
            _fechaVencimiento == null
                ? "Seleccionar Fecha"
                : DateFormat('dd/MM/yyyy').format(_fechaVencimiento!),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
  Widget _buildBotonGuardar() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _isSaving ? null : _ejecutarGuardado,
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "REGISTRAR DONACIÓN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
