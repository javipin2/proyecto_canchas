import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/reserva.dart';
import '../../../../models/cancha.dart';
import '../../../../models/horario.dart';
import '../../../../providers/cancha_provider.dart';

class AdminRegistroReservasScreen extends StatefulWidget {
  const AdminRegistroReservasScreen({super.key});

  @override
  AdminRegistroReservasScreenState createState() =>
      AdminRegistroReservasScreenState();
}

class AdminRegistroReservasScreenState
    extends State<AdminRegistroReservasScreen> with TickerProviderStateMixin {
  List<Reserva> _reservas = [];
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _viewTable = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  final Color _primaryColor = const Color(0xFF3C4043);
  final Color _secondaryColor = const Color(0xFF4285F4);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = const Color(0xFFF8F9FA);
  final Color _disabledColor = const Color(0xFFDADCE0);
  final Color _reservedColor = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservas();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadReservas() async {
    setState(() {
      _isLoading = true;
      _reservas.clear();
    });
    try {
      final canchaProvider =
          Provider.of<CanchaProvider>(context, listen: false);
      // Cargar todas las canchas para mapear cancha_id a Cancha
      await canchaProvider
          .fetchCanchas('Sede 1'); // Cargar para una sede por defecto
      await canchaProvider.fetchCanchas('Sede 2'); // Cargar para la otra sede
      final canchasMap = {
        for (var cancha in canchaProvider.canchas) cancha.id: cancha
      };

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La consulta tardó demasiado');
      });

      List<Reserva> reservasTemp = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final canchaId = data['cancha_id'] ?? '';
          final cancha = canchasMap[canchaId] ??
              Cancha(
                id: canchaId,
                nombre: 'Cancha desconocida',
                descripcion: '',
                imagen: 'assets/cancha_demo.png',
                techada: false,
                ubicacion: '',
                precio: 0.0,
                sede: data['sede'] ?? '',
              );

          final reserva = Reserva(
            id: doc.id,
            cancha: cancha,
            fecha: DateFormat('yyyy-MM-dd')
                .parse(data['fecha'] ?? DateTime.now().toString()),
            horario: _parseHorario(data['horario'] ?? '12:00 AM'),
            sede: data['sede'] ?? '',
            tipoAbono: data['estado'] == 'completo'
                ? TipoAbono.completo
                : TipoAbono.parcial,
            montoTotal: (data['valor'] ?? 0).toDouble(),
            montoPagado: (data['montoPagado'] ?? 0).toDouble(),
            nombre: data['nombre'],
            telefono: data['telefono'],
            email: data['correo'],
            confirmada: data['confirmada'] ?? false,
          );
          reservasTemp.add(reserva);
        } catch (e) {
          debugPrint('Error al procesar documento: $e');
        }
      }

      if (mounted) {
        setState(() {
          _reservas = reservasTemp;
          if (_selectedDate != null) {
            _filterReservasByDate();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al cargar reservas: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeController.reset();
        _fadeController.forward();
      }
    }
  }

  Horario _parseHorario(String horarioStr) {
    try {
      final pattern = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false);
      final match = pattern.firstMatch(horarioStr);
      if (match == null)
        return Horario(hora: const TimeOfDay(hour: 0, minute: 0));

      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return Horario(hora: TimeOfDay(hour: hour, minute: minute));
    } catch (e) {
      debugPrint('Error al parsear horario: $e');
      return Horario(hora: const TimeOfDay(hour: 0, minute: 0));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _viewTable = !_viewTable;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _secondaryColor,
              onPrimary: Colors.white,
              onSurface: _primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _secondaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (newDate != null && mounted) {
      setState(() {
        _selectedDate = newDate;
        _filterReservasByDate();
      });
    }
  }

  void _filterReservasByDate() {
    if (_selectedDate == null) {
      _loadReservas();
      return;
    }
    final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    setState(() {
      _reservas = _reservas
          .where((reserva) =>
              DateFormat('yyyy-MM-dd').format(reserva.fecha) == fechaStr)
          .toList();
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadReservas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registro de Reservas',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        foregroundColor: _primaryColor,
        actions: [
          Tooltip(
            message: _viewTable ? 'Vista en Lista' : 'Vista en Tabla',
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(
                  _viewTable
                      ? Icons.view_list_rounded
                      : Icons.table_chart_rounded,
                  color: _secondaryColor,
                ),
                onPressed: _toggleView,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Animate(
                effects: [
                  FadeEffect(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuad,
                  ),
                  SlideEffect(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuad,
                  ),
                ],
                child: _buildFechaSelector(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _secondaryColor),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cargando reservas...',
                              style: GoogleFonts.montserrat(
                                color: _primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _reservas.isEmpty
                        ? Center(
                            child: Text(
                              _selectedDate == null
                                  ? 'No hay reservas registradas'
                                  : 'No hay reservas para la fecha seleccionada',
                              style:
                                  GoogleFonts.montserrat(color: _primaryColor),
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _viewTable &&
                                    MediaQuery.of(context).size.width > 600
                                ? _buildDataTable()
                                : _buildListView(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaSelector() {
    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: _secondaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por Fecha',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Text(
                      _selectedDate == null
                          ? 'Todas las fechas'
                          : DateFormat('EEEE d MMMM, yyyy', 'es')
                              .format(_selectedDate!),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.redAccent),
                onPressed: _clearDateFilter,
                tooltip: 'Limpiar filtro',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 56,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: _primaryColor,
            fontSize: 14,
          ),
          dataTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: _primaryColor,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Cancha')),
            DataColumn(label: Text('Sede')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Horario')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Confirmada')),
          ],
          rows: _reservas.asMap().entries.map((entry) {
            final reserva = entry.value;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    reserva.id.length > 8
                        ? '${reserva.id.substring(0, 8)}...'
                        : reserva.id,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(Text(reserva.cancha.nombre)),
                DataCell(Text(reserva.sede)),
                DataCell(Text(DateFormat('dd/MM/yyyy').format(reserva.fecha))),
                DataCell(Text(reserva.horario.horaFormateada)),
                DataCell(Text(reserva.nombre ?? 'N/A')),
                DataCell(Text(reserva.telefono ?? 'N/A')),
                DataCell(Text(reserva.email ?? 'N/A')),
                DataCell(Text(
                  reserva.tipoAbono == TipoAbono.completo
                      ? 'Completo'
                      : 'Parcial',
                  style: TextStyle(
                    color: reserva.tipoAbono == TipoAbono.completo
                        ? _reservedColor
                        : Colors.orange,
                  ),
                )),
                DataCell(Icon(
                  reserva.confirmada ? Icons.check_circle : Icons.cancel,
                  color: reserva.confirmada ? _reservedColor : Colors.redAccent,
                  size: 20,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _reservas.length,
      itemBuilder: (context, index) {
        final reserva = _reservas[index];
        return Animate(
          effects: [
            FadeEffect(
              delay: Duration(milliseconds: 50 * (index % 10)),
              duration: const Duration(milliseconds: 400),
            ),
            SlideEffect(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
              delay: Duration(milliseconds: 50 * (index % 10)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
            ),
          ],
          child: Card(
            elevation: 0,
            color: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: reserva.confirmada ? _reservedColor : _disabledColor,
                width: 1.5,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                '${reserva.cancha.nombre} - ${reserva.sede}',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(reserva.fecha)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color.fromRGBO(60, 64, 67, 0.8),
                    ),
                  ),
                  Text(
                    'Horario: ${reserva.horario.horaFormateada}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color.fromRGBO(60, 64, 67, 0.8),
                    ),
                  ),
                  Text(
                    'Cliente: ${reserva.nombre ?? 'N/A'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color.fromRGBO(60, 64, 67, 0.8),
                    ),
                  ),
                  Text(
                    'Teléfono: ${reserva.telefono ?? 'N/A'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color.fromRGBO(60, 64, 67, 0.8),
                    ),
                  ),
                  Text(
                    'Email: ${reserva.email ?? 'N/A'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color.fromRGBO(60, 64, 67, 0.8),
                    ),
                  ),
                  Text(
                    'Estado: ${reserva.tipoAbono == TipoAbono.completo ? 'Completo' : 'Parcial'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: reserva.tipoAbono == TipoAbono.completo
                          ? _reservedColor
                          : Colors.orange,
                    ),
                  ),
                  Text(
                    'Confirmada: ${reserva.confirmada ? 'Sí' : 'No'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: reserva.confirmada
                          ? _reservedColor
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
