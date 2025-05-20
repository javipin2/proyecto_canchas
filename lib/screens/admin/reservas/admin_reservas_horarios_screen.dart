import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/cancha.dart';
import '../../../models/reserva.dart';
import '../../../models/horario.dart';
import '../../../providers/cancha_provider.dart';
import '../../../providers/sede_provider.dart';
import 'detalles_reserva_screen.dart';
import 'agregar_reserva_screen.dart';

class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  AdminReservasScreenState createState() => AdminReservasScreenState();
}

class AdminReservasScreenState extends State<AdminReservasScreen>
    with TickerProviderStateMixin {
  String _selectedSede = 'Sede 1';
  Cancha? _selectedCancha;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _viewGrid = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  List<Cancha> _canchas = [];
  List<Reserva> _reservas = [];
  final Map<int, Reserva> _reservedMap = {};

  final List<int> _hours = List<int>.generate(19, (index) => index + 5);
  final List<String> _sedes = ['Sede 1', 'Sede 2'];

  final Color _primaryColor = const Color(0xFF3C4043);
  final Color _secondaryColor = const Color(0xFF4285F4);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = const Color(0xFFF8F9FA);
  final Color _disabledColor = const Color(0xFFDADCE0);
  final Color _reservedColor = const Color(0xFF4CAF50);
  final Color _availableColor = const Color(0xFFEEEEEE);

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
      final sedeProvider = Provider.of<SedeProvider>(context, listen: false);
      setState(() {
        _selectedSede = sedeProvider.sede;
      });
      _loadCanchas();
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

  int _parseHora(String horarioStr) {
    if (horarioStr.isEmpty) return 0;

    final pattern = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false);
    final match = pattern.firstMatch(horarioStr);

    if (match == null) return 0;

    int hour = int.tryParse(match.group(1) ?? '0') ?? 0;
    final ampm = match.group(3)?.toUpperCase();

    if (ampm == 'PM' && hour != 12) {
      hour += 12;
    } else if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }

    return hour;
  }

  Future<void> _loadCanchas() async {
    final canchaProvider = Provider.of<CanchaProvider>(context, listen: false);
    try {
      await canchaProvider.fetchCanchas(_selectedSede);
      setState(() {
        _canchas = canchaProvider.canchas;
        _selectedCancha = _canchas.isNotEmpty ? _canchas.first : null;
      });
      await _loadReservas();
    } catch (e) {
      _showErrorSnackBar('Error al cargar canchas: $e');
    }
  }

  Future<void> _loadReservas() async {
    if (_selectedCancha == null) return;
    setState(() {
      _isLoading = true;
      _reservas.clear();
      _reservedMap.clear();
    });
    try {
      final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .where('fecha', isEqualTo: fechaStr)
          .where('sede', isEqualTo: _selectedSede)
          .where('cancha_id', isEqualTo: _selectedCancha!.id)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La consulta tardó demasiado');
      });

      List<Reserva> reservasTemp = [];
      for (var doc in querySnapshot.docs) {
        try {
          final reserva = Reserva.fromFirestore(doc);
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('horario')) {
            String storedHorario = data['horario'] ?? "";
            int correctHour = _parseHora(storedHorario);
            TimeOfDay newTime = TimeOfDay(
                hour: correctHour, minute: reserva.horario.hora.minute);
            reserva.horario = Horario(hora: newTime);
          }
          if ((reserva.cancha.nombre.isEmpty) && _selectedCancha != null) {
            reserva.cancha = _selectedCancha!;
          }
          _reservedMap[reserva.horario.hora.hour] = reserva;
          reservasTemp.add(reserva);
        } catch (e) {
          debugPrint("Error al procesar documento: $e");
        }
      }

      if (mounted) {
        setState(() {
          _reservas = reservasTemp;
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
      _viewGrid = !_viewGrid;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
    if (newDate != null && newDate != _selectedDate && mounted) {
      setState(() {
        _selectedDate = newDate;
      });
      await _loadReservas();
    }
  }

  void _viewReservaDetails(Reserva reserva) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetallesReservaScreen(reserva: reserva),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _loadReservas());
  }

  void _addReserva(int hora) {
    if (_selectedCancha == null) return;
    final horario = Horario(hora: TimeOfDay(hour: hora, minute: 0));
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AgregarReservaScreen(
          cancha: _selectedCancha!,
          sede: _selectedSede,
          horario: horario,
          fecha: _selectedDate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _loadReservas());
  }

  void _confirmDelete(Reserva reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Estás seguro de que deseas eliminar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: _primaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('reservas')
                    .doc(reserva.id)
                    .delete();
                Navigator.pop(context);
                await _loadReservas();
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Error al eliminar la reserva: $e');
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Administración de Reservas',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        foregroundColor: _primaryColor,
        actions: [
          Tooltip(
            message: _viewGrid ? 'Vista en Lista' : 'Vista en Calendario',
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(
                  _viewGrid
                      ? Icons.view_list_rounded
                      : Icons.calendar_view_month_rounded,
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
                child: _buildSedeYCanchaSelectors(),
              ),
              const SizedBox(height: 16),
              Animate(
                effects: [
                  FadeEffect(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuad,
                  ),
                  SlideEffect(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuad,
                  ),
                ],
                child: _buildFechaSelector(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedCancha == null
                    ? Center(
                        child: Text(
                          'Selecciona una cancha para ver los horarios',
                          style: GoogleFonts.montserrat(color: _primaryColor),
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
                        child: _viewGrid ? _buildGridView() : _buildListView(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSedeYCanchaSelectors() {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sede',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _disabledColor),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSede,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: _secondaryColor),
                        isExpanded: true,
                        style: GoogleFonts.montserrat(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        items: _sedes
                            .map((sede) => DropdownMenuItem(
                                  value: sede,
                                  child: Text(sede),
                                ))
                            .toList(),
                        onChanged: (newSede) {
                          if (newSede != null) {
                            setState(() {
                              _selectedSede = newSede;
                            });
                            _loadCanchas();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancha',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _disabledColor),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Cancha>(
                        value: _selectedCancha,
                        hint: Text(
                          'Selecciona Cancha',
                          style: GoogleFonts.montserrat(
                            color: Color.fromRGBO(60, 64, 67, 0.5),
                          ),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: _secondaryColor),
                        isExpanded: true,
                        style: GoogleFonts.montserrat(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        items: _canchas
                            .map((cancha) => DropdownMenuItem<Cancha>(
                                  value: cancha,
                                  child: Text(cancha.nombre),
                                ))
                            .toList(),
                        onChanged: (newCancha) {
                          setState(() {
                            _selectedCancha = newCancha;
                          });
                          _loadReservas();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectDate(context),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha Seleccionada',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE d MMMM, yyyy', 'es').format(_selectedDate),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color.fromRGBO(60, 64, 67, 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            'Horarios Disponibles',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        if (_isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando horarios...',
                    style: GoogleFonts.montserrat(
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 5 : 3,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 800 ? 2 : 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _hours.length,
              itemBuilder: (context, index) {
                final hour = _hours[index];
                final now = DateTime.now();
                final isToday = _selectedDate.year == now.year &&
                    _selectedDate.month == now.month &&
                    _selectedDate.day == now.day;
                final isPast = isToday && hour < now.hour;
                final isReserved = _reservedMap.containsKey(hour);
                final reserva = isReserved ? _reservedMap[hour] : null;

                Color bgColor;
                Color textColor;
                IconData statusIcon;
                String statusText;

                if (isPast) {
                  bgColor = Color.fromRGBO(218, 220, 224, 0.5);
                  textColor = Colors.grey;
                  statusIcon = Icons.history;
                  statusText = 'Pasado';
                } else if (isReserved) {
                  bgColor = Color.fromRGBO(76, 175, 80, 0.2);
                  textColor = _reservedColor;
                  statusIcon = Icons.event_busy;
                  statusText = 'Reservado';
                } else {
                  bgColor = _availableColor;
                  textColor = _primaryColor;
                  statusIcon = Icons.event_available;
                  statusText = 'Disponible';
                }

                return Animate(
                  effects: [
                    FadeEffect(
                      delay: Duration(milliseconds: 50 * (index % 10)),
                      duration: const Duration(milliseconds: 400),
                    ),
                    ScaleEffect(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.0, 1.0),
                      delay: Duration(milliseconds: 50 * (index % 10)),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuad,
                    ),
                  ],
                  child: Hero(
                    tag: 'hora_grid_$hour',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isPast
                            ? null
                            : () {
                                if (isReserved) {
                                  _viewReservaDetails(reserva!);
                                } else {
                                  _addReserva(hour);
                                }
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPast
                                  ? _disabledColor
                                  : isReserved
                                      ? _reservedColor
                                      : Color.fromRGBO(60, 64, 67, 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isPast
                                    ? Colors.black.withAlpha(13)
                                    : isReserved
                                        ? Color.fromRGBO(76, 175, 80, 0.15)
                                        : Color.fromRGBO(60, 64, 67, 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('h:mm a')
                                    .format(DateTime(2022, 1, 1, hour)),
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 14,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            'Horarios Disponibles',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        if (_isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando horarios...',
                    style: GoogleFonts.montserrat(
                      color: Color.fromRGBO(60, 64, 67, 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _hours.length,
              itemBuilder: (context, index) {
                final hour = _hours[index];
                final now = DateTime.now();
                final isToday = _selectedDate.year == now.year &&
                    _selectedDate.month == now.month &&
                    _selectedDate.day == now.day;
                final isPast = isToday && hour < now.hour;
                final isReserved = _reservedMap.containsKey(hour);
                final reserva = isReserved ? _reservedMap[hour] : null;

                Color bgColor;
                Color textColor;
                IconData statusIcon;
                String statusText;

                if (isPast) {
                  bgColor = Color.fromRGBO(218, 220, 224, 0.5);
                  textColor = Colors.grey;
                  statusIcon = Icons.history;
                  statusText = 'Pasado';
                } else if (isReserved) {
                  bgColor = Color.fromRGBO(76, 175, 80, 0.1);
                  textColor = _reservedColor;
                  statusIcon = Icons.event_busy;
                  statusText = 'Reservado';
                } else {
                  bgColor = Colors.white;
                  textColor = _primaryColor;
                  statusIcon = Icons.event_available;
                  statusText = 'Disponible';
                }

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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Hero(
                      tag: 'hora_list_$hour',
                      child: Material(
                        color: Colors.transparent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPast
                                  ? _disabledColor
                                  : isReserved
                                      ? _reservedColor
                                      : Color.fromRGBO(60, 64, 67, 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isPast
                                    ? Colors.black.withAlpha(13)
                                    : isReserved
                                        ? Color.fromRGBO(76, 175, 80, 0.15)
                                        : Color.fromRGBO(60, 64, 67, 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: isPast
                                ? null
                                : () {
                                    if (isReserved) {
                                      _viewReservaDetails(reserva!);
                                    } else {
                                      _addReserva(hour);
                                    }
                                  },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Color.fromRGBO(218, 220, 224, 0.2)
                                    : isReserved
                                        ? Color.fromRGBO(76, 175, 80, 0.2)
                                        : _availableColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  statusIcon,
                                  color: textColor,
                                ),
                              ),
                            ),
                            title: Text(
                              DateFormat('h:mm a')
                                  .format(DateTime(2022, 1, 1, hour)),
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              '$statusText${isReserved ? ' por: ${reserva?.nombre ?? "Cliente"}' : isPast ? '' : ' para reservar'}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Color.fromRGBO(
                                    textColor.r.toInt(),
                                    textColor.g.toInt(),
                                    textColor.b.toInt(),
                                    0.8),
                              ),
                            ),
                            trailing: isReserved && !isPast
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: _secondaryColor, size: 20),
                                        onPressed: () =>
                                            _viewReservaDetails(reserva!),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.redAccent, size: 20),
                                        onPressed: () =>
                                            _confirmDelete(reserva!),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  )
                                : Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Color.fromRGBO(
                                        textColor.r.toInt(),
                                        textColor.g.toInt(),
                                        textColor.b.toInt(),
                                        0.5),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
