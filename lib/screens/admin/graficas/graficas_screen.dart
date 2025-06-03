import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/reserva.dart';
import '../../../models/cancha.dart';
import '../../../providers/cancha_provider.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({super.key});

  @override
  GraficasScreenState createState() => GraficasScreenState();
}

class GraficasScreenState extends State<GraficasScreen> {
  DateTime? _selectedDate;
  String? _selectedSede;
  String? _selectedCanchaId;
  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  bool _isLoading = false;
  String _filterType = 'Mes'; // Día, Semana, Mes

  final Color _primaryColor = const Color(0xFF263238);
  final Color _secondaryColor = const Color(0xFF0288D1);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _disabledColor = const Color(0xFFB0BEC5);
  final Color _reservedColor = const Color(0xFF2ECC71);
  final Color _accentColor = const Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final canchaProvider =
          Provider.of<CanchaProvider>(context, listen: false);
      await canchaProvider.fetchAllCanchas();
      await canchaProvider.fetchHorasReservadas();
      final canchasMap = {
        for (var cancha in canchaProvider.canchas) cancha.id: cancha
      };

      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection('reservas');

      if (_selectedSede != null && _selectedSede!.isNotEmpty) {
        query = query.where('sede', isEqualTo: _selectedSede);
      }
      if (_selectedCanchaId != null && _selectedCanchaId!.isNotEmpty) {
        query = query.where('cancha_id', isEqualTo: _selectedCanchaId);
      }
      if (_selectedDate != null) {
        if (_filterType == 'Día') {
          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          query = query.where('fecha', isEqualTo: dateStr);
        } else if (_filterType == 'Semana') {
          final startOfWeek = _selectedDate!
              .subtract(Duration(days: _selectedDate!.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          query = query
              .where('fecha',
                  isGreaterThanOrEqualTo:
                      DateFormat('yyyy-MM-dd').format(startOfWeek))
              .where('fecha',
                  isLessThanOrEqualTo:
                      DateFormat('yyyy-MM-dd').format(endOfWeek));
        } else if (_filterType == 'Mes') {
          final monthStr = DateFormat('yyyy-MM').format(_selectedDate!);
          query = query
              .where('fecha', isGreaterThanOrEqualTo: '$monthStr-01')
              .where('fecha', isLessThanOrEqualTo: '$monthStr-31');
        }
      }

      final querySnapshot =
          await query.get().timeout(const Duration(seconds: 10));

      _reservas = querySnapshot.docs
          .map((doc) => Reserva.fromFirestoreWithCanchas(doc, canchasMap))
          .toList();
      _filteredReservas = _reservas;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Reserva> filtered = _reservas;

    if (_selectedDate != null) {
      if (_filterType == 'Día') {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        filtered = filtered.where((reserva) {
          return DateFormat('yyyy-MM-dd').format(reserva.fecha) == dateStr;
        }).toList();
      } else if (_filterType == 'Semana') {
        final startOfWeek =
            _selectedDate!.subtract(Duration(days: _selectedDate!.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filtered = filtered.where((reserva) {
          return reserva.fecha
                  .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              reserva.fecha.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
      } else if (_filterType == 'Mes') {
        final monthStr = DateFormat('yyyy-MM').format(_selectedDate!);
        filtered = filtered.where((reserva) {
          return DateFormat('yyyy-MM').format(reserva.fecha) == monthStr;
        }).toList();
      }
    }

    setState(() => _filteredReservas = filtered);
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedSede = null;
      _selectedCanchaId = null;
      _filterType = 'Mes';
      _filteredReservas = _reservas;
    });
    _loadData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _secondaryColor,
              onPrimary: Colors.white,
              onSurface: _primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _secondaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
      _loadData();
    }
  }

  void _selectSede(String? sede) {
    setState(() {
      _selectedSede = sede;
      _selectedCanchaId = null;
      _applyFilters();
    });
    _loadData();
  }

  void _selectCancha(String? canchaId) {
    setState(() {
      _selectedCanchaId = canchaId;
      _applyFilters();
    });
    _loadData();
  }

  List<PieChartSectionData> _getConfirmationData() {
    if (_filteredReservas.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: _disabledColor,
          title: 'Sin datos',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
      ];
    }
    final confirmadas =
        _filteredReservas.where((r) => r.confirmada).length.toDouble();
    final noConfirmadas = (_filteredReservas.length - confirmadas).toDouble();
    return [
      PieChartSectionData(
        value: confirmadas,
        color: _reservedColor,
        title: confirmadas == 0 ? '' : confirmadas.toInt().toString(),
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      ),
      PieChartSectionData(
        value: noConfirmadas,
        color: Colors.redAccent,
        title: noConfirmadas == 0 ? '' : noConfirmadas.toInt().toString(),
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      ),
    ];
  }

  List<BarChartGroupData> _getSedeSalesData() {
    if (_filteredReservas.isEmpty) return [];
    final sedes = _filteredReservas.map((r) => r.sede).toSet().toList();
    return List.generate(sedes.length, (index) {
      final sede = sedes[index];
      final total = _filteredReservas
          .where((r) => r.sede == sede)
          .fold(0.0, (total, r) => total + r.montoPagado);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: _secondaryColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  List<BarChartGroupData> _getCanchaData() {
    if (_filteredReservas.isEmpty) return [];
    final canchas =
        _filteredReservas.map((r) => r.cancha.nombre).toSet().toList();
    return List.generate(canchas.length, (index) {
      final cancha = canchas[index];
      final count = _filteredReservas
          .where((r) => r.cancha.nombre == cancha)
          .length
          .toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            color: _accentColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  List<LineChartBarData> _getSalesData() {
    if (_filteredReservas.isEmpty) return [];
    final salesData = <DateTime, double>{};
    for (var reserva in _filteredReservas) {
      DateTime key;
      if (_filterType == 'Día') {
        key = DateTime(
            reserva.fecha.year, reserva.fecha.month, reserva.fecha.day);
      } else if (_filterType == 'Semana') {
        final startOfWeek =
            reserva.fecha.subtract(Duration(days: reserva.fecha.weekday - 1));
        key = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      } else {
        key = DateTime(reserva.fecha.year, reserva.fecha.month);
      }
      salesData[key] = (salesData[key] ?? 0) + reserva.montoPagado;
    }
    final sortedKeys = salesData.keys.toList()..sort();
    return [
      LineChartBarData(
        spots: sortedKeys
            .map((date) => FlSpot(
                date.millisecondsSinceEpoch.toDouble(), salesData[date]!))
            .toList(),
        isCurved: true,
        color: _secondaryColor,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Color.fromRGBO(2, 136, 209, 0.2),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canchaProvider = Provider.of<CanchaProvider>(context);
    final canchas = canchaProvider.canchas
        .where(
            (cancha) => _selectedSede == null || cancha.sede == _selectedSede)
        .toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Análisis de Reservas"),
        backgroundColor: _cardColor,
        elevation: 2,
        foregroundColor: _primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_secondaryColor)),
                  const SizedBox(height: 16),
                  Text('Cargando datos...',
                      style: TextStyle(color: _primaryColor)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: MediaQuery.of(context).size.width > 600
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftColumn(canchaProvider, canchas),
                        const SizedBox(width: 16),
                        _filteredReservas.isEmpty
                            ? _buildEmptyState()
                            : _buildRightColumn(),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeftColumn(canchaProvider, canchas),
                          const SizedBox(height: 16),
                          _filteredReservas.isEmpty
                              ? _buildEmptyState()
                              : _buildRightColumn(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildLeftColumn(CanchaProvider canchaProvider, List<Cancha> canchas) {
    final totalVentas =
        _filteredReservas.fold(0.0, (total, r) => total + r.montoPagado);
    final reservasConfirmadas =
        _filteredReservas.where((r) => r.confirmada).length;
    final reservasTotales = _filteredReservas.length;
    final totalCanchas = canchaProvider.canchas.length;
    final totalSedes = canchaProvider.canchas.map((c) => c.sede).toSet().length;
    final canchaMasPedida = _filteredReservas.isEmpty
        ? 'Sin datos'
        : _filteredReservas
                .map((r) => r.cancha.nombre)
                .toList()
                .fold<Map<String, int>>({}, (map, cancha) {
                  map[cancha] = (map[cancha] ?? 0) + 1;
                  return map;
                })
                .entries
                .toList()
                .isEmpty
            ? 'Sin datos'
            : _filteredReservas
                .map((r) => r.cancha.nombre)
                .toList()
                .fold<Map<String, int>>({}, (map, cancha) {
                  map[cancha] = (map[cancha] ?? 0) + 1;
                  return map;
                })
                .entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
    final sedeMasPedida = _filteredReservas.isEmpty
        ? 'Sin datos'
        : _filteredReservas
                .map((r) => r.sede)
                .toList()
                .fold<Map<String, int>>({}, (map, sede) {
                  map[sede] = (map[sede] ?? 0) + 1;
                  return map;
                })
                .entries
                .toList()
                .isEmpty
            ? 'Sin datos'
            : _filteredReservas
                .map((r) => r.sede)
                .toList()
                .fold<Map<String, int>>({}, (map, sede) {
                  map[sede] = (map[sede] ?? 0) + 1;
                  return map;
                })
                .entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;

    return Expanded(
      flex: 1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: _cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _filterType,
                      hint: 'Seleccionar tipo de filtro',
                      items: const ['Día', 'Semana', 'Mes'],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value!;
                          _applyFilters();
                        });
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedSede,
                      hint: 'Todas las sedes',
                      items: [
                        null,
                        ...canchaProvider.canchas.map((c) => c.sede).toSet()
                      ],
                      onChanged: _selectSede,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedCanchaId,
                      hint: 'Todas las canchas',
                      items: [null, ...canchas.map((cancha) => cancha.id)],
                      itemBuilder: (value) => value == null
                          ? const Text('Todas las canchas')
                          : Text(canchas
                              .firstWhere((c) => c.id == value,
                                  orElse: () => Cancha(
                                      id: '',
                                      nombre: 'Desconocida',
                                      descripcion: '',
                                      imagen: '',
                                      techada: false,
                                      ubicacion: '',
                                      precio: 0.0,
                                      sede: ''))
                              .nombre),
                      onChanged: _selectCancha,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
                'Total Ingresos',
                '\$${totalVentas.toStringAsFixed(2)}',
                Icons.attach_money,
                _secondaryColor),
            _buildMetricCard(
                'Reservas Confirmadas',
                '$reservasConfirmadas/$reservasTotales',
                Icons.check_circle,
                _reservedColor),
            _buildMetricCard('Total Canchas', '$totalCanchas',
                Icons.sports_soccer, _accentColor),
            _buildMetricCard(
                'Total Sedes', '$totalSedes', Icons.store, Colors.purpleAccent),
            _buildMetricCard(
                'Cancha Más Pedida', canchaMasPedida, Icons.star, _accentColor),
            _buildMetricCard('Sede Más Pedida', sedeMasPedida,
                Icons.location_on, Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChartSection(
              title: 'Ingresos por Sede',
              chart: _getSedeSalesData().isEmpty
                  ? const Center(child: Text('No hay datos para mostrar'))
                  : BarChart(
                      BarChartData(
                        barGroups: _getSedeSalesData(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final sedes = _filteredReservas
                                    .map((r) => r.sede)
                                    .toSet()
                                    .toList();
                                if (value.toInt() >= sedes.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  angle: 45 * 3.1415927 / 180,
                                  child: Text(
                                    sedes[value.toInt()],
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: _disabledColor)),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _filteredReservas.fold(0.0,
                                          (total, r) => total + r.montoPagado) /
                                      5 >
                                  0
                              ? _filteredReservas.fold(0.0,
                                      (total, r) => total + r.montoPagado) /
                                  5
                              : 1.0,
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) =>
                                    BarTooltipItem(
                              '\$${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            _buildChartSection(
              title: 'Reservas por Estado',
              chart: PieChart(
                PieChartData(
                  sections: _getConfirmationData(),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  startDegreeOffset: 270,
                ),
              ),
            ),
            _buildChartSection(
              title: 'Canchas Más Reservadas',
              chart: _getCanchaData().isEmpty
                  ? const Center(child: Text('No hay datos para mostrar'))
                  : BarChart(
                      BarChartData(
                        barGroups: _getCanchaData(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final canchas = _filteredReservas
                                    .map((r) => r.cancha.nombre)
                                    .toSet()
                                    .toList();
                                if (value.toInt() >= canchas.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  angle: 45 * 3.1415927 / 180,
                                  child: Text(
                                    canchas[value.toInt()],
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: _disabledColor)),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval:
                              _filteredReservas.length.toDouble() / 5 > 0
                                  ? _filteredReservas.length.toDouble() / 5
                                  : 1.0,
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) =>
                                    BarTooltipItem(
                              '${rod.toY.toInt()}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            _buildChartSection(
              title: 'Ingresos ($_filterType)',
              chart: _getSalesData().isEmpty
                  ? const Center(child: Text('No hay datos para mostrar'))
                  : LineChart(
                      LineChartData(
                        lineBarsData: _getSalesData(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt());
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    _filterType == 'Día'
                                        ? DateFormat('dd MMM').format(date)
                                        : _filterType == 'Semana'
                                            ? DateFormat('dd MMM').format(date)
                                            : DateFormat('MMM yy').format(date),
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: _disabledColor)),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _filteredReservas.fold(0.0,
                                          (total, r) => total + r.montoPagado) /
                                      5 >
                                  0
                              ? _filteredReservas.fold(0.0,
                                      (total, r) => total + r.montoPagado) /
                                  5
                              : 1.0,
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                return LineTooltipItem(
                                  '\$${spot.y.toStringAsFixed(2)}',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      flex: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: _disabledColor),
            const SizedBox(height: 16),
            Text(
              'No hay reservas para los filtros seleccionados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba ajustar los filtros o recargar los datos',
              style: TextStyle(
                fontSize: 14,
                color: _disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    String? value,
    required String hint,
    required List<String?> items,
    Widget Function(String?)? itemBuilder,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _disabledColor),
        filled: true,
        fillColor: _cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _disabledColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _disabledColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _secondaryColor, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: itemBuilder != null ? itemBuilder(item) : Text(item ?? hint),
        );
      }).toList(),
      onChanged: onChanged,
      style: TextStyle(color: _primaryColor),
      icon: Icon(Icons.keyboard_arrow_down, color: _secondaryColor),
      isExpanded: true,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          border: Border.all(color: _disabledColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Seleccionar fecha'
                    : _filterType == 'Día'
                        ? DateFormat('dd MMMM yyyy', 'es')
                            .format(_selectedDate!)
                        : _filterType == 'Semana'
                            ? 'Semana del ${DateFormat('dd MMMM yyyy', 'es').format(_selectedDate!.subtract(Duration(days: _selectedDate!.weekday - 1)))}'
                            : DateFormat('MMMM yyyy', 'es')
                                .format(_selectedDate!),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _primaryColor,
                ),
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                onPressed: _clearFilters,
                tooltip: 'Limpiar filtros',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget chart}) {
    return Card(
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}
