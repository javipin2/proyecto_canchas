import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/reserva.dart';

class ReservaScreen extends StatefulWidget {
  final Reserva reserva;

  const ReservaScreen({Key? key, required this.reserva}) : super(key: key);

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _abonoController = TextEditingController();
  bool _procesando = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _montoPagado = 0;

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
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _montoPagado = widget.reserva.montoPagado;
    _abonoController.text = _montoPagado.toStringAsFixed(0);

    _animationController.forward();
  }

  Future<void> _confirmarReserva() async {
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _procesando = true;
      });

      HapticFeedback.mediumImpact();

      widget.reserva.nombre = _nombreController.text;
      widget.reserva.telefono = _telefonoController.text;
      widget.reserva.email = _emailController.text;
      widget.reserva.montoPagado = _montoPagado;
      widget.reserva.tipoAbono = _montoPagado >= widget.reserva.montoTotal
          ? TipoAbono.completo
          : TipoAbono.parcial;

      try {
        await FirebaseFirestore.instance
            .collection('reservas')
            .add(widget.reserva.toFirestore());

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text("¡Reserva confirmada con éxito!"),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Error inesperado: $e'),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _procesando = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _abonoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(symbol: "\$", decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Confirmar Reserva',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[800]!,
                            Colors.grey[900]!,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.sports_soccer,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.reserva.cancha.nombre,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('EEEE, d MMM yyyy', 'es').format(widget.reserva.fecha)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                title: 'Fecha',
                                value: DateFormat('dd/MM/yyyy')
                                    .format(widget.reserva.fecha),
                                icon: Icons.calendar_today,
                              ),
                              _buildInfoItem(
                                title: 'Hora',
                                value: widget.reserva.horario.horaFormateada,
                                icon: Icons.access_time,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                title: 'Precio Total',
                                value: currencyFormat
                                    .format(widget.reserva.montoTotal),
                                icon: Icons.attach_money,
                              ),
                              _buildInfoItem(
                                title: 'Abono Inicial',
                                value: currencyFormat
                                    .format(widget.reserva.montoPagado),
                                icon: Icons.payment,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Tus datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre Completo',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.text,
                          validatorMsg: 'Por favor ingresa tu nombre',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validatorMsg: 'Por favor ingresa tu teléfono',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validatorMsg: 'Por favor ingresa tu correo',
                          extraValidation: (value) {
                            if (value != null &&
                                (value.isEmpty ||
                                    !value.contains('@') ||
                                    !value.contains('.'))) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        if (widget.reserva.tipoAbono == TipoAbono.parcial) ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _abonoController,
                            label: 'Abono (mínimo 20000)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validatorMsg: 'Por favor ingresa un abono',
                            extraValidation: (value) {
                              final abono = double.tryParse(value ?? '0') ?? 0;
                              if (abono < 20000) {
                                return 'El abono debe ser al menos 20000';
                              }
                              if (abono > widget.reserva.montoTotal) {
                                return 'El abono no puede superar el precio total';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _montoPagado = double.tryParse(value) ??
                                    widget.reserva.montoPagado;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 40),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 55,
                          child: _procesando
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey[800]!),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _confirmarReserva,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[850],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.grey.withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    'CONFIRMAR RESERVA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String validatorMsg,
    String? Function(String?)? extraValidation,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 16,
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorMsg;
        }
        if (extraValidation != null) {
          return extraValidation(value);
        }
        return null;
      },
    );
  }
}
