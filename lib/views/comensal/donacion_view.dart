import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- AGREGADO para identificar al usuario
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DonacionView extends StatefulWidget {
  const DonacionView({Key? key}) : super(key: key);

  @override
  State<DonacionView> createState() => _DonacionViewState();
}

class _DonacionViewState extends State<DonacionView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colores Identidad Alimenta Perú
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color accentSolidario = const Color(0xFFD65A5A);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color cardBorder = const Color(0xFFBDDAC8);

  // Estados del Formulario
  bool _esDinero = true;
  bool _isSaving = false;
  String? _catSeleccionada;
  String? _prodSeleccionado;
  String _unidadSeleccionada = 'kg';
  DateTime? _fechaVencimiento;

  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _cantCtrl = TextEditingController();

  // Lista Maestra Sincronizada
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

  // --- FUNCIÓN DE ALERTAS (Reutilizable) ---
  void _mostrarSnackBar(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: esError ? Colors.redAccent : darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LÓGICA DE GUARDADO CON DESCUENTO DE SALDO ---
  Future<void> _ejecutarGuardado() async {
    double monto = 0.0;

    // 1. VALIDACIÓN DE CAMPOS
    if (_esDinero) {
      if (_montoCtrl.text.isEmpty) {
        _mostrarSnackBar("Por favor, ingresa el monto a donar");
        return;
      }
      monto = double.tryParse(_montoCtrl.text) ?? 0.0;
      if (monto <= 0) {
        _mostrarSnackBar("El monto debe ser mayor a S/ 0.00");
        return;
      }
    } else {
      if (_prodSeleccionado == null ||
          _cantCtrl.text.isEmpty ||
          _fechaVencimiento == null) {
        _mostrarSnackBar("Por favor, completa todos los campos de productos");
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // 2. OBTENER EL USUARIO ACTUAL
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("NO_AUTH");

      final docUsuarioRef = _firestore.collection('usuarios').doc(userId);

      // 3. EJECUTAR TRANSACCIÓN (Para que sea seguro)
      await _firestore.runTransaction((transaction) async {
        // Si es dinero, verificamos y descontamos el saldo
        if (_esDinero) {
          final snapshotUsuario = await transaction.get(docUsuarioRef);
          if (!snapshotUsuario.exists) throw Exception("NO_USER");

          final dataUsuario = snapshotUsuario.data() as Map<String, dynamic>;
          final double saldoActual = (dataUsuario['saldo'] ?? 0).toDouble();

          // Validación de Saldo Insuficiente
          if (saldoActual < monto) {
            throw Exception("SALDO_INSUFICIENTE");
          }

          // Descontar del saldo
          transaction.update(docUsuarioRef, {'saldo': saldoActual - monto});
        }

        // Crear el registro de la Donación
        final docDonacionRef = _firestore.collection('Donaciones').doc();
        transaction.set(docDonacionRef, {
          'usuario_id': userId, // Para saber quién hizo la donación
          'tipo': _esDinero ? 'Efectivo' : 'Abarrotes',
          'monto': _esDinero ? monto : 0.0,
          'categoria': !_esDinero ? _catSeleccionada : null,
          'producto': !_esDinero ? _prodSeleccionado : null,
          'unidad': !_esDinero ? _unidadSeleccionada : null,
          'cantidad': !_esDinero ? double.tryParse(_cantCtrl.text) : 0.0,
          'fecha_vencimiento': _fechaVencimiento != null
              ? Timestamp.fromDate(_fechaVencimiento!)
              : null,
          'fecha_registro': FieldValue.serverTimestamp(),
          'estado': _esDinero
              ? 'Completada'
              : 'Pendiente de Entrega', // Si es dinero, se completa al instante
        });
      });

      // 4. SI TODO FUE BIEN, MOSTRAR EXITO
      _mostrarDialogoExito();
    } catch (e) {
      // 5. MANEJO DE ERRORES VISUALES
      if (e.toString().contains("SALDO_INSUFICIENTE")) {
        _mostrarSnackBar(
          "⚠️ Saldo insuficiente en tu Billetera. Recarga para continuar.",
        );
      } else if (e.toString().contains("NO_AUTH")) {
        _mostrarSnackBar("⚠️ Sesión expirada. Vuelve a iniciar sesión.");
      } else {
        _mostrarSnackBar("❌ Ocurrió un error al procesar tu donación.");
        debugPrint(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 70,
            ),
            const SizedBox(height: 20),
            Text(
              "¡Donación Registrada!",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Gracias por apoyar la labor de las ollas comunes.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(
                    context,
                  ); // Cierra la vista actual para volver a la billetera
                },
                child: Text(
                  "FINALIZAR",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        elevation: 0,
        backgroundColor: darkGreen,
        centerTitle: true,
        title: Text(
          "Nueva Donación",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("MODALIDAD"),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildOptionCard(
                  Icons.payments_rounded,
                  "DINERO",
                  _esDinero,
                  () => setState(() => _esDinero = true),
                ),
                const SizedBox(width: 12),
                _buildOptionCard(
                  Icons.inventory_2_rounded,
                  "PRODUCTOS",
                  !_esDinero,
                  () => setState(() => _esDinero = false),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_esDinero) ...[
                    _buildFieldLabel("MONTO (S/)"),
                    _buildTextField(
                      _montoCtrl,
                      "0.00",
                      Icons.monetization_on_outlined,
                      isNumber: true,
                    ),
                  ] else ...[
                    _buildFieldLabel("CATEGORÍA"),
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _catSeleccionada,
                          hint: const Text("Seleccione"),
                          items: listaMaestra.keys
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) => setState(() {
                            _catSeleccionada = val;
                            _prodSeleccionado = null;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildFieldLabel("PRODUCTO"),
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _prodSeleccionado,
                          hint: const Text("Seleccione"),
                          items: _catSeleccionada == null
                              ? null
                              : listaMaestra[_catSeleccionada]!
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (val) =>
                              setState(() => _prodSeleccionado = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("UNIDAD"),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _unidadSeleccionada,
                                    items: ['kg', 'lts', 'und']
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(
                                      () => _unidadSeleccionada = val!,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("CANTIDAD"),
                              _buildTextField(
                                _cantCtrl,
                                "0",
                                Icons.add_shopping_cart_rounded,
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildFieldLabel("FECHA VENCIMIENTO"),
                    InkWell(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null)
                          setState(() => _fechaVencimiento = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: darkGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fechaVencimiento == null
                                  ? "Seleccionar Fecha"
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaVencimiento!),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isSaving ? null : _ejecutarGuardado,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "AGREGAR DONACIÓN",
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
    );
  }

  // --- COMPONENTES PREMIUM (Sin cambios) ---
  Widget _buildSectionLabel(String t) => Text(
    t,
    style: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: const Color(0xFF7A9E8A),
    ),
  );
  Widget _buildFieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: darkGreen.withOpacity(0.6),
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: darkGreen.withOpacity(0.4)),
      filled: true,
      fillColor: bgColor.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildDropdownContainer({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: bgColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(15),
    ),
    child: child,
  );

  Widget _buildOptionCard(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? accentSolidario : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : cardBorder.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF9CBFAD),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : const Color(0xFF7A9E8A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
