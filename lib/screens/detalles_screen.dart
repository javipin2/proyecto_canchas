import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/cancha.dart';
import '../models/horario.dart';
import '../models/reserva.dart';
import 'reserva_screen.dart';

class DetallesScreen extends StatefulWidget {
  final Cancha cancha;
  final DateTime fecha;
  final Horario horario;
  final String sede;

  const DetallesScreen({
    Key? key,
    required this.cancha,
    required this.fecha,
    required this.horario,
    required this.sede,
  }) : super(key: key);

  @override
  State<DetallesScreen> createState() => _DetallesScreenState();
}

class _DetallesScreenState extends State<DetallesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Iniciar animación después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double precioCompleto = widget.cancha.precio;
    const double abono = 20000; // Valor fijo para abono
    final currencyFormat =
        NumberFormat.currency(symbol: "\$", decimalDigits: 0);

    // Obtenemos el tema actual para usar sus colores
    final theme = Theme.of(context);

    // Efecto de vibración suave al presionar los botones
    void hapticFeedback() {
      HapticFeedback.lightImpact();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Detalles de la Reserva',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Detalles de la cancha - Card elevada con sombra
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre de la cancha
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.sports_soccer_rounded,
                                        color: theme.primaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          widget.cancha.nombre,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Fecha y hora
                                  _buildInfoRow(
                                    Icons.calendar_today_rounded,
                                    'Fecha',
                                    DateFormat('EEEE, d MMMM y', 'es')
                                        .format(widget.fecha),
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1),
                                  ),

                                  _buildInfoRow(
                                    Icons.access_time_rounded,
                                    'Hora',
                                    widget.horario.horaFormateada,
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1),
                                  ),

                                  _buildInfoRow(
                                    Icons.location_on_rounded,
                                    'Sede',
                                    widget.sede,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Información de precios
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información de Pago',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPriceRow(
                                    'Precio completo',
                                    currencyFormat.format(precioCompleto),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPriceRow(
                                    'Abono mínimo',
                                    currencyFormat.format(abono),
                                  ),
                                ],
                              ),
                            ),

                            // Espaciador que expande pero es scrollable
                            SizedBox(
                                height: constraints.maxHeight > 600
                                    ? constraints.maxHeight * 0.15
                                    : 16),

                            // Botones de acción - ahora dentro del área scrollable
                            _buildActionButton(
                              label: 'Abonar y Reservar',
                              price: currencyFormat.format(abono),
                              color: Colors.grey[800]!,
                              onPressed: () {
                                hapticFeedback();
                                _animateButtonPress(() {
                                  _hacerReserva(TipoAbono.parcial, abono);
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            _buildActionButton(
                              label: 'Pagar Completo',
                              price: currencyFormat.format(precioCompleto),
                              color: theme.primaryColor,
                              onPressed: () {
                                hapticFeedback();
                                _animateButtonPress(() {
                                  _hacerReserva(
                                      TipoAbono.completo, precioCompleto);
                                });
                              },
                              isPrimary: true,
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String price,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _animateButtonPress(VoidCallback action) {
    // Pequeña animación de botón al presionar
    HapticFeedback.mediumImpact();
    action();
  }

  /// **Método para crear la reserva y subirla a Firebase Firestore**
  Future<void> _hacerReserva(TipoAbono tipoAbono, double montoPagado) async {
    Reserva reserva = Reserva(
      cancha: widget.cancha,
      fecha: widget.fecha,
      horario: widget.horario,
      sede: widget.sede,
      tipoAbono: tipoAbono,
      montoTotal: widget.cancha.precio,
      montoPagado: montoPagado,
      confirmada: true,
      id: '',
    );

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Subir reserva a Firestore
      await FirebaseFirestore.instance
          .collection('reservas')
          .add(reserva.toFirestore());

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Navegamos a la pantalla de reserva y esperamos el resultado
      final bool? reservaExitosa = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ReservaScreen(reserva: reserva),
        ),
      );

      if (reservaExitosa == true) {
        Navigator.of(context)
            .pop(true); // Indicar a HorariosScreen que hubo una reserva
      }
    } catch (e) {
      // Cerrar indicador de carga si hay error
      Navigator.pop(context);

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la reserva: $e'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception('🔥 Error al registrar la reserva en Firestore: $e');
    }
  }
}
