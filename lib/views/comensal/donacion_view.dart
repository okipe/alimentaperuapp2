import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alimentaperu_app/viewmodels/donacion_viewmodel.dart';

class DonacionView extends StatefulWidget {
  const DonacionView({super.key});
  @override
  State<DonacionView> createState() => _DonacionViewState();
}

class _DonacionViewState extends State<DonacionView> {
  final TextEditingController _cantidadController = TextEditingController();
  String? _categoriaSeleccionada;
  String? _productoSeleccionado;
  String _unidadSeleccionada = 'kg';
  DateTime _fechaVencimiento = DateTime.now();

  bool _isSaving = false;

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color accentGreen = const Color(0xFF2E7D52);
  final Color bgColor = const Color(0xFFF4F7F5);

  final Map<String, List<String>> productosPorCategoria = {
    'Abarrotes': ['Arroz', 'Fideos', 'Aceite', 'Azúcar', 'Sal'],
    'Menestras': ['Lenteja', 'Frijol', 'Arveja partida', 'Garbanzo'],
    'Verduras': ['Cebolla', 'Tomate', 'Papa', 'Zanahoria', 'Ajo'],
    'Carnes': ['Pollo', 'Res', 'Pescado', 'Cerdo'],
  };

  // 🔥 NOTIFICACIÓN ULTRARRÁPIDA
  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Cierra cualquier mensaje anterior al instante
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: const Duration(
          milliseconds: 1500,
        ), // 🔥 Desaparece rápido en 1.5 segundos
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "REGISTRO DE DONACIÓN",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: darkGreen,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumFormulario(),
            const SizedBox(height: 35),
            _buildHistorialPremium(uid),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFormulario() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDropdown(
            "Categoría",
            _categoriaSeleccionada,
            productosPorCategoria.keys.toList(),
            (v) {
              setState(() {
                _categoriaSeleccionada = v;
                _productoSeleccionado =
                    null; // Limpia el producto si cambia la categoría
              });
            },
          ),
          const SizedBox(height: 15),
          _buildDropdown(
            "Producto",
            _productoSeleccionado,
            _categoriaSeleccionada != null
                ? productosPorCategoria[_categoriaSeleccionada]!
                : [],
            (v) => setState(() => _productoSeleccionado = v),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      hintText: "Cantidad",
                      prefixIcon: Icon(
                        Icons.scale,
                        color: Colors.grey,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  null,
                  _unidadSeleccionada,
                  ['kg', 'lt', 'unid'],
                  (v) => setState(() => _unidadSeleccionada = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: darkGreen),
              title: Text(
                "Vence: ${DateFormat('dd/MM/yyyy').format(_fechaVencimiento)}",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onTap: () async {
                DateTime? p = await showDatePicker(
                  context: context,
                  initialDate: _fechaVencimiento,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(primary: darkGreen),
                    ),
                    child: child!,
                  ),
                );
                if (p != null) setState(() => _fechaVencimiento = p);
              },
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving ? Colors.grey[400] : darkGreen,
                elevation: _isSaving ? 0 : 5,
                shadowColor: darkGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _isSaving ? null : _confirmarDonacion,
              child: _isSaving
                  ? const SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      "GUARDAR DONACIÓN",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarDonacion() {
    double? cant = double.tryParse(_cantidadController.text);
    if (_productoSeleccionado == null || cant == null || cant <= 0) {
      _notificar("⚠️ Completa el producto y la cantidad", Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            Icon(Icons.volunteer_activism, size: 55, color: darkGreen),
            const SizedBox(height: 15),
            Text(
              "Confirmar",
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Text(
          "¿Registrar donación de $cant $_unidadSeleccionada de $_productoSeleccionado?",
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: GoogleFonts.dmSans(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              _ejecutarGuardado(cant);
            },
            child: Text(
              "Sí, Donar",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ejecutarGuardado(double cant) async {
    setState(() {
      _isSaving = true;
    });

    final vm = Provider.of<DonacionViewModel>(context, listen: false);
    bool ok = await vm.registrarDonacion(
      productoNombre: _productoSeleccionado!,
      cantidadDonada: cant,
      unidad: _unidadSeleccionada,
      categoria: _categoriaSeleccionada!,
      fechaVencimiento: _fechaVencimiento,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        // 🔥 MAGIA AQUÍ: Si todo salió bien, vaciamos TODOS los campos
        if (ok) {
          _cantidadController.clear();
          _categoriaSeleccionada = null;
          _productoSeleccionado = null;
          _unidadSeleccionada = 'kg';
          _fechaVencimiento = DateTime.now(); // Resetea la fecha a hoy
        }
      });

      // 🚀 Notificación ultrarrápida
      if (ok) {
        _notificar("✅ Donación guardada con éxito", Colors.green);
      }
    }
  }

  Widget _buildHistorialPremium(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MIS REGISTROS RECIENTES",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Donaciones')
              .where('donanteID', isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snap.data!.docs.where((d) {
              var data = d.data() as Map;
              return data.containsKey('fecha_registro') &&
                  data['fecha_registro'] != null;
            }).toList();

            docs.sort(
              (a, b) => (b.data() as Map)['fecha_registro'].compareTo(
                (a.data() as Map)['fecha_registro'],
              ),
            );

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Aún no tienes donaciones",
                        style: GoogleFonts.dmSans(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                var d = docs[i].data() as Map<String, dynamic>;
                String fecha = DateFormat(
                  'dd/MM/yy - HH:mm',
                ).format((d['fecha_registro'] as Timestamp).toDate());

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        color: darkGreen,
                      ),
                    ),
                    title: Text(
                      "${d['producto']?.toUpperCase()} (${d['cantidad']} ${d['unidad']})",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Registrado: $fecha",
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String? h,
    String? v,
    List<String> items,
    Function(String?) onC,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: v,
          hint: h != null
              ? Text(h, style: GoogleFonts.dmSans(color: Colors.grey[600]))
              : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          items: items
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
          onChanged: onC,
        ),
      ),
    );
  }
}
