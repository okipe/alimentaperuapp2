import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alimentaperu_app/viewmodels/estado_pagos_viewmodel.dart';
import 'package:intl/intl.dart';

class EstadoPagosView extends StatefulWidget {
  const EstadoPagosView({Key? key}) : super(key: key);

  @override
  State<EstadoPagosView> createState() => _EstadoPagosViewState();
}

class _EstadoPagosViewState extends State<EstadoPagosView> {
  // 0 = Muestra Reservas, 1 = Muestra Recargas, 2 = Muestra Donaciones
  int _historialSeleccionado = 0;

  void _mostrarPasarelaRecarga(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PasarelaPagosDialog(),
    );
  }

  String _formatearFecha(Timestamp? timestamp) {
    if (timestamp == null) return "Procesando...";
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  String _formatearFechaCorta(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    return DateFormat('dd/MM/yy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EstadoPagosViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(
          "Mi Billetera",
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: viewModel.getStreamUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Sin datos de usuario"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          double saldoActual = (userData['saldo'] ?? 0).toDouble();
          String nombreUsuario = userData['nombre'] ?? "Usuario";
          String apellidoUsuario = userData['apellido'] ?? "";
          String nombreCompleto = "$nombreUsuario $apellidoUsuario".trim();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B5E20),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 20,
                        right: 20,
                      ),
                      child: _buildTarjetaBilleteraPremium(
                        saldoActual,
                        nombreCompleto,
                        context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectorHistorial(),
                      const SizedBox(height: 20),
                      if (_historialSeleccionado == 0)
                        _buildListaReservas(viewModel)
                      else if (_historialSeleccionado == 1)
                        _buildListaRecargas(viewModel)
                      else
                        _buildListaDonaciones(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTarjetaBilleteraPremium(
    double saldo,
    String nombre,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2B0E), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ALIMENTA PERÚ",
                style: GoogleFonts.urbanist(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.contactless_outlined,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "Saldo Disponible",
            style: GoogleFonts.urbanist(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            "S/ ${saldo.toStringAsFixed(2)}",
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TITULAR",
                      style: GoogleFonts.urbanist(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombre.toUpperCase(),
                      style: GoogleFonts.urbanist(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _mostrarPasarelaRecarga(context),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  "RECARGAR",
                  style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorHistorial() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _buildTabItem(0, "Reservas"),
          _buildTabItem(1, "Recargas"),
          _buildTabItem(2, "Donaciones"),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _historialSeleccionado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _historialSeleccionado = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.urbanist(
              color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildListaReservas(EstadoPagosViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
      stream: viewModel.getHistorialPagos(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return SelectableText(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red, fontSize: 10),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator(color: Color(0xFF1B5E20));

        var docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = dataA['fecha'] as Timestamp?;
          final dateB = dataB['fecha'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        if (docs.isEmpty)
          return _textEmpty(
            "No tienes reservas recientes.",
            Icons.restaurant_rounded,
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return _buildFilaHistorialPremium(
              titulo: data['semana'] ?? 'Consumo de Menú',
              estado: "Pagado",
              fecha: _formatearFecha(data['fecha'] as Timestamp?),
              monto: "- S/ ${(data['monto'] ?? 0).toStringAsFixed(2)}",
              esIngreso: false,
              icono: Icons.restaurant_rounded,
            );
          },
        );
      },
    );
  }

  Widget _buildListaRecargas(EstadoPagosViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
      stream: viewModel.getHistorialRecargas(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return SelectableText(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red, fontSize: 10),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator(color: Color(0xFF1B5E20));

        var docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = dataA['fecha'] as Timestamp?;
          final dateB = dataB['fecha'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        if (docs.isEmpty)
          return _textEmpty(
            "No tienes solicitudes de recarga.",
            Icons.account_balance_wallet_rounded,
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool aprobado = data['estado'] == 'aprobado';
            return _buildFilaHistorialPremium(
              titulo: "Recarga vía ${data['metodo_pago'] ?? 'Efectivo'}",
              estado: aprobado ? "Aprobado" : "Pendiente",
              fecha: _formatearFecha(data['fecha'] as Timestamp?),
              monto: "+ S/ ${(data['monto'] ?? 0).toStringAsFixed(2)}",
              esIngreso: true,
              icono: aprobado
                  ? Icons.verified_rounded
                  : Icons.hourglass_empty_rounded,
              colorIcono: aprobado ? Colors.green[700]! : Colors.orange[700]!,
            );
          },
        );
      },
    );
  }

  Widget _buildListaDonaciones() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null)
      return const Center(
        child: Text("Debes iniciar sesión para ver tus donaciones."),
      );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Donaciones')
          .where('usuario_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator(color: Color(0xFF1B5E20));

        var docs = snapshot.data?.docs.toList() ?? [];

        docs.sort((a, b) {
          var dA =
              (a.data() as Map<String, dynamic>)['fecha_registro']
                  as Timestamp?;
          var dB =
              (b.data() as Map<String, dynamic>)['fecha_registro']
                  as Timestamp?;
          if (dA == null && dB == null) return 0;
          if (dA == null) return 1;
          if (dB == null) return -1;
          return dB.compareTo(dA);
        });

        var donacionesDinero = docs
            .where(
              (d) => (d.data() as Map<String, dynamic>)['tipo'] == 'Efectivo',
            )
            .toList();
        var donacionesProducto = docs
            .where(
              (d) => (d.data() as Map<String, dynamic>)['tipo'] != 'Efectivo',
            )
            .toList();

        if (docs.isEmpty)
          return _textEmpty(
            "Aún no has realizado ninguna donación.",
            Icons.favorite_border_rounded,
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (donacionesDinero.isNotEmpty) ...[
              Text(
                "Donaciones en Dinero",
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              _buildTablaDonaciones(donacionesDinero, esDinero: true),
              const SizedBox(height: 30),
            ],
            if (donacionesProducto.isNotEmpty) ...[
              Text(
                "Donaciones en Productos",
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              _buildTablaDonaciones(donacionesProducto, esDinero: false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTablaDonaciones(
    List<QueryDocumentSnapshot> docs, {
    required bool esDinero,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF1B5E20).withOpacity(0.05),
                  ),
                  horizontalMargin: 15,
                  columnSpacing: 25,
                  columns: [
                    DataColumn(
                      label: Text(
                        "Fecha",
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    if (esDinero)
                      DataColumn(
                        label: Text(
                          "Monto",
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    if (!esDinero) ...[
                      DataColumn(
                        label: Text(
                          "Producto",
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Cant.",
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                    DataColumn(
                      label: Text(
                        "Estado",
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                  rows: docs.map((d) {
                    var data = d.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            _formatearFechaCorta(
                              data['fecha_registro'] as Timestamp?,
                            ),
                            style: GoogleFonts.urbanist(fontSize: 13),
                          ),
                        ),
                        if (esDinero)
                          DataCell(
                            Text(
                              "S/ ${(data['monto'] ?? 0).toStringAsFixed(2)}",
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD65A5A),
                              ),
                            ),
                          ),
                        if (!esDinero) ...[
                          DataCell(
                            Text(
                              data['producto'] ?? '-',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${data['cantidad']} ${data['unidad']}",
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: data['estado'] == 'Completada'
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data['estado'] ?? '',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: data['estado'] == 'Completada'
                                    ? Colors.green[700]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _textEmpty(String msg, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 50),
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 15),
          Text(
            msg,
            style: GoogleFonts.urbanist(
              color: Colors.grey[500],
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFilaHistorialPremium({
    required String titulo,
    required String estado,
    required String fecha,
    required String monto,
    required bool esIngreso,
    required IconData icono,
    Color? colorIcono,
  }) {
    Color baseColor =
        colorIcono ?? (esIngreso ? Colors.green[700]! : Colors.orange[700]!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: baseColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$estado • $fecha",
                  style: GoogleFonts.urbanist(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            monto,
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: esIngreso ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGET INTERNO: DIÁLOGO DE RECARGA MODO PROFESIONAL (MEJORADO CON ESTADO)
// ==============================================================================
class _PasarelaPagosDialog extends StatefulWidget {
  const _PasarelaPagosDialog();
  @override
  State<_PasarelaPagosDialog> createState() => _PasarelaPagosDialogState();
}

class _PasarelaPagosDialogState extends State<_PasarelaPagosDialog> {
  String _metodo = 'Yape';
  final _montoCtrl = TextEditingController();
  final _nroOpCtrl = TextEditingController();
  bool _isSubmitting = false; // <-- NUEVA VARIABLE DE ESTADO (LOADING)

  final _metodos = {
    'Yape': {
      'color': const Color(0xFF74007A),
      'icono': Icons.qr_code_2_rounded,
      'inst': 'Yapea al 987 654 321 (Comedor VES)',
    },
    'Plin': {
      'color': const Color(0xFF00B2A9),
      'icono': Icons.qr_code_scanner_rounded,
      'inst': 'Plinea al 987 654 321 (Comedor VES)',
    },
    'Efectivo': {
      'color': const Color(0xFF1B5E20),
      'icono': Icons.storefront_rounded,
      'inst': 'Acércate a caja y entrega el efectivo',
    },
  };

  // --- NUEVO: DIÁLOGO DE ÉXITO DE SOLICITUD ---
  void _mostrarExito(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 20),
              Text(
                "¡Solicitud Enviada!",
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Tu voucher ha sido enviado correctamente. Un administrador verificará y confirmará tu recarga en breve.",
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  color: Colors.grey[600],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "ENTENDIDO",
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color colorActivo = _metodos[_metodo]!['color'] as Color;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recargar Saldo",
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Selecciona tu método de pago",
              style: GoogleFonts.urbanist(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: _metodos.keys.map((m) {
                bool isSelected = _metodo == m;
                Color mColor = _metodos[m]!['color'] as Color;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _metodo = m;
                      _nroOpCtrl.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? mColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? mColor : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: mColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _metodos[m]!['icono'] as IconData,
                            color: isSelected ? Colors.white : Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorActivo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorActivo.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorActivo,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _metodos[_metodo]!['inst'] as String,
                      style: GoogleFonts.urbanist(
                        color: colorActivo,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "Monto",
                      labelStyle: GoogleFonts.urbanist(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      prefixText: "S/ ",
                      prefixStyle: GoogleFonts.urbanist(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorActivo, width: 2),
                      ),
                    ),
                  ),
                ),
                if (_metodo != 'Efectivo') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _nroOpCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.urbanist(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: "Nro. Operación",
                        labelStyle: GoogleFonts.urbanist(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        hintText: "Ej. 123456",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorActivo, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorActivo,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // --- BOTÓN MEJORADO CON CARGA Y CONFIRMACIÓN ---
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_montoCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ingresa un monto válido"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (_metodo != 'Efectivo' && _nroOpCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ingresa el número de operación"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 1. Activar animación de carga
                        setState(() => _isSubmitting = true);

                        try {
                          final vm = Provider.of<EstadoPagosViewModel>(
                            context,
                            listen: false,
                          );

                          // 2. Esperar que se guarde en Firebase
                          await vm.solicitarRecarga(
                            double.parse(_montoCtrl.text),
                            _metodo,
                            _nroOpCtrl.text,
                          );

                          // 3. Cerrar el modal actual y mostrar el éxito
                          if (context.mounted) {
                            Navigator.pop(context); // Cierra la pasarela
                            _mostrarExito(
                              context,
                            ); // Muestra el mensaje de validación
                          }
                        } catch (e) {
                          // Si algo falla, detener la carga
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "ENVIAR VOUCHER",
                        style: GoogleFonts.urbanist(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
