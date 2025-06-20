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
  String _filterType = 'Mes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final canchaProvider = Provider.of<CanchaProvider>(context, listen: false);
      await canchaProvider.fetchAllCanchas();
      await canchaProvider.fetchHorasReservadas();

      final canchasMap = {
        for (var cancha in canchaProvider.canchas) cancha.id: cancha
      };

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .get()
          .timeout(const Duration(seconds: 10));

      _reservas = querySnapshot.docs
          .map((doc) => Reserva.fromFirestoreWithCanchas(doc, canchasMap))
          .toList();

      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Reserva> filtered = List.from(_reservas);

    // Aplicar filtro de sede
    if (_selectedSede?.isNotEmpty == true) {
      filtered = filtered.where((reserva) => reserva.sede == _selectedSede).toList();
    }

    // Aplicar filtro de cancha
    if (_selectedCanchaId?.isNotEmpty == true) {
      filtered = filtered.where((reserva) => reserva.cancha.id == _selectedCanchaId).toList();
    }

    // Aplicar filtro de fecha si está seleccionada
    if (_selectedDate != null) {
      filtered = filtered.where((reserva) => _isSameDay(reserva.fecha, _selectedDate!)).toList();
    }

    setState(() => _filteredReservas = filtered);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  bool _isInSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
    final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));
    return _isSameDay(startOfWeek1, startOfWeek2);
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedSede = null;
      _selectedCanchaId = null;
      _filterType = 'Mes';
    });
    _applyFilters();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  Map<String, dynamic> _getStats() {
    final currentDate = DateTime.now();
    final totalCanchas = Provider.of<CanchaProvider>(context, listen: false).canchas.length;
    final totalSedes = Provider.of<CanchaProvider>(context, listen: false)
        .canchas
        .map((c) => c.sede)
        .toSet()
        .length;

    // Filtrar reservas según el período actual
    final periodFilteredReservas = _filteredReservas.where((reserva) {
      switch (_filterType) {
        case 'Día':
          return _isSameDay(reserva.fecha, currentDate);
        case 'Semana':
          return _isInSameWeek(reserva.fecha, currentDate);
        case 'Mes':
          return _isSameMonth(reserva.fecha, currentDate);
        default:
          return true;
      }
    }).toList();

    final totalReservas = periodFilteredReservas.length;

    String canchaMasPedida = 'Sin datos';
    String sedeMasPedida = 'Sin datos';
    String horaMasPedida = 'Sin datos';

    if (periodFilteredReservas.isNotEmpty) {
      final canchaCount = <String, int>{};
      final sedeCount = <String, int>{};
      final horaCount = <String, int>{};

      for (var reserva in periodFilteredReservas) {
        canchaCount[reserva.cancha.nombre] = (canchaCount[reserva.cancha.nombre] ?? 0) + 1;
        sedeCount[reserva.sede] = (sedeCount[reserva.sede] ?? 0) + 1;
        horaCount[reserva.horario.horaFormateada] = (horaCount[reserva.horario.horaFormateada] ?? 0) + 1;
      }

      if (canchaCount.isNotEmpty) {
        canchaMasPedida = canchaCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
      if (sedeCount.isNotEmpty) {
        sedeMasPedida = sedeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
      if (horaCount.isNotEmpty) {
        horaMasPedida = horaCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
    }

    return {
      'totalReservas': totalReservas,
      'totalCanchas': totalCanchas,
      'totalSedes': totalSedes,
      'canchaMasPedida': canchaMasPedida,
      'sedeMasPedida': sedeMasPedida,
      'horaMasPedida': horaMasPedida,
    };
  }

  List<BarChartGroupData> _getSedeReservasData() {
    if (_filteredReservas.isEmpty) return [];

    final currentDate = DateTime.now();
    final periodFilteredReservas = _filteredReservas.where((reserva) {
      switch (_filterType) {
        case 'Día':
          return _isSameDay(reserva.fecha, currentDate);
        case 'Semana':
          return _isInSameWeek(reserva.fecha, currentDate);
        case 'Mes':
          return _isSameMonth(reserva.fecha, currentDate);
        default:
          return true;
      }
    }).toList();

    final sedeCount = <String, int>{};
    for (var reserva in periodFilteredReservas) {
      sedeCount[reserva.sede] = (sedeCount[reserva.sede] ?? 0) + 1;
    }

    final sedes = sedeCount.keys.toList();
    return List.generate(sedes.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sedeCount[sedes[index]]!.toDouble(),
            color: Colors.blue,
            width: 20,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _getCanchaReservasData() {
    if (_filteredReservas.isEmpty) return [];

    final currentDate = DateTime.now();
    final periodFilteredReservas = _filteredReservas.where((reserva) {
      switch (_filterType) {
        case 'Día':
          return _isSameDay(reserva.fecha, currentDate);
        case 'Semana':
          return _isInSameWeek(reserva.fecha, currentDate);
        case 'Mes':
          return _isSameMonth(reserva.fecha, currentDate);
        default:
          return true;
      }
    }).toList();

    final canchaCount = <String, int>{};
    for (var reserva in periodFilteredReservas) {
      canchaCount[reserva.cancha.nombre] = (canchaCount[reserva.cancha.nombre] ?? 0) + 1;
    }

    final canchas = canchaCount.keys.toList();
    return List.generate(canchas.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: canchaCount[canchas[index]]!.toDouble(),
            color: Colors.orange,
            width: 20,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _getHorarioReservasData() {
    if (_filteredReservas.isEmpty) return [];

    final currentDate = DateTime.now();
    final periodFilteredReservas = _filteredReservas.where((reserva) {
      switch (_filterType) {
        case 'Día':
          return _isSameDay(reserva.fecha, currentDate);
        case 'Semana':
          return _isInSameWeek(reserva.fecha, currentDate);
        case 'Mes':
          return _isSameMonth(reserva.fecha, currentDate);
        default:
          return true;
      }
    }).toList();

    final horaCount = <String, int>{};
    for (var reserva in periodFilteredReservas) {
      horaCount[reserva.horario.horaFormateada] = (horaCount[reserva.horario.horaFormateada] ?? 0) + 1;
    }

    final horas = horaCount.keys.toList();
    return List.generate(horas.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: horaCount[horas[index]]!.toDouble(),
            color: Colors.green,
            width: 20,
          ),
        ],
      );
    });
  }

  Map<String, dynamic> _getReservasTemporalesData() {
    if (_filteredReservas.isEmpty)
      return {'spots': <FlSpot>[], 'labels': <String>[]};

    final currentDate = DateTime.now();
    final reservasData = <String, int>{};

    // Determinar el rango histórico según el período
    int historicalRange;
    switch (_filterType) {
      case 'Día':
        historicalRange = 10; // Últimos 10 días
        break;
      case 'Semana':
        historicalRange = 4; // Últimas 4 semanas
        break;
      case 'Mes':
        historicalRange = 6; // Últimos 6 meses
        break;
      default:
        historicalRange = 6;
    }

    for (var reserva in _filteredReservas) {
      String key;
      DateTime startDate;
      switch (_filterType) {
        case 'Día':
          startDate = currentDate.subtract(Duration(days: historicalRange - 1));
          if (reserva.fecha.isBefore(startDate) || reserva.fecha.isAfter(currentDate)) continue;
          key = DateFormat('dd/MM/yyyy').format(reserva.fecha);
          break;
        case 'Semana':
          startDate = currentDate.subtract(Duration(days: (historicalRange - 1) * 7));
          final startOfWeek = reserva.fecha.subtract(Duration(days: reserva.fecha.weekday - 1));
          if (startOfWeek.isBefore(startDate) || startOfWeek.isAfter(currentDate)) continue;
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          key = '${DateFormat('dd/MM').format(startOfWeek)}-${DateFormat('dd/MM').format(endOfWeek)}';
          break;
        case 'Mes':
        default:
          startDate = DateTime(currentDate.year, currentDate.month - historicalRange + 1, 1);
          if (reserva.fecha.isBefore(startDate) || reserva.fecha.isAfter(currentDate)) continue;
          key = DateFormat('MMM yyyy', 'es').format(reserva.fecha);
          break;
      }
      reservasData[key] = (reservasData[key] ?? 0) + 1;
    }

    final sortedEntries = reservasData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    final labels = sortedEntries.map((entry) => entry.key).toList();

    return {
      'spots': spots,
      'labels': labels,
    };
  }

  @override
  Widget build(BuildContext context) {
    final canchaProvider = Provider.of<CanchaProvider>(context);
    final canchas = canchaProvider.canchas
        .where((cancha) => _selectedSede == null || cancha.sede == _selectedSede)
        .toList();
    final stats = _getStats();
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Análisis de Reservas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filtros',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildFilterDropdown()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildDateSelector()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildSedeDropdown(canchaProvider)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildCanchaDropdown(canchas)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildFilterDropdown(),
                                    const SizedBox(height: 12),
                                    _buildDateSelector(),
                                    const SizedBox(height: 12),
                                    _buildSedeDropdown(canchaProvider),
                                    const SizedBox(height: 12),
                                    _buildCanchaDropdown(canchas),
                                  ],
                                ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearFilters,
                            child: const Text('Limpiar Filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estadísticas - Período: $_filterType',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildStatsColumn(stats, 0)),
                                    Expanded(child: _buildStatsColumn(stats, 1)),
                                  ],
                                )
                              : _buildStatsColumn(stats, -1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredReservas.isNotEmpty) ...[
                    isWide
                        ? Row(
                            children: [
                              Expanded(
                                  child: _buildChart('Reservas por Sede', _buildSedeChart())),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _buildChart('Reservas por Cancha', _buildCanchaChart())),
                            ],
                          )
                        : Column(
                            children: [
                              _buildChart('Reservas por Sede', _buildSedeChart()),
                              const SizedBox(height: 16),
                              _buildChart('Reservas por Cancha', _buildCanchaChart()),
                            ],
                          ),
                    const SizedBox(height: 16),
                    _buildChart('Horarios Más Pedidos', _buildHorarioChart()),
                    const SizedBox(height: 16),
                    _buildChart('Reservas en el Tiempo ($_filterType)', _buildTemporalChart()),
                  ] else
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay datos para mostrar',
                              style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: _filterType,
      decoration: const InputDecoration(
        labelText: 'Período',
        border: OutlineInputBorder(),
      ),
      items: ['Día', 'Semana', 'Mes']
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) {
        if (value != null && value != _filterType) {
          setState(() {
            _filterType = value;
            _selectedDate = null; // Limpiar fecha al cambiar período
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(_selectedDate == null
            ? 'Todas las fechas'
            : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
      ),
    );
  }

  Widget _buildSedeDropdown(CanchaProvider canchaProvider) {
    return DropdownButtonFormField<String>(
      value: _selectedSede,
      decoration: const InputDecoration(
        labelText: 'Sede',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas las sedes')),
        ...canchaProvider.canchas
            .map((c) => c.sede)
            .toSet()
            .map((sede) => DropdownMenuItem(value: sede, child: Text(sede)))
      ],
      onChanged: (value) {
        setState(() {
          _selectedSede = value;
          _selectedCanchaId = null;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildCanchaDropdown(List<Cancha> canchas) {
    return DropdownButtonFormField<String>(
      value: _selectedCanchaId,
      decoration: const InputDecoration(
        labelText: 'Cancha',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas las canchas')),
        ...canchas.map((cancha) =>
            DropdownMenuItem(value: cancha.id, child: Text(cancha.nombre)))
      ],
      onChanged: (value) {
        setState(() => _selectedCanchaId = value);
        _applyFilters();
      },
    );
  }

  Widget _buildStatsColumn(Map<String, dynamic> stats, int column) {
    final items = [
      ['Total Reservas', '${stats['totalReservas']}'],
      ['Total Canchas', '${stats['totalCanchas']}'],
      ['Total Sedes', '${stats['totalSedes']}'],
      ['Cancha Popular', stats['canchaMasPedida']],
      ['Sede Popular', stats['sedeMasPedida']],
      ['Hora Popular', stats['horaMasPedida']],
    ];

    if (column == -1) {
      return Column(
        children: items.map((item) => _buildStatItem(item[0], item[1])).toList(),
      );
    } else {
      final start = column * 3;
      final end = (start + 3).clamp(0, items.length);
      return Column(
        children: items
            .sublist(start, end)
            .map((item) => _buildStatItem(item[0], item[1]))
            .toList(),
      );
    }
  }

  Widget _buildStatItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 250, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeChart() {
    return BarChart(
      BarChartData(
        barGroups: _getSedeReservasData(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final sedes = _filteredReservas.map((r) => r.sede).toSet().toList();
                return value.toInt() >= 0 && value.toInt() < sedes.length
                    ? Text(sedes[value.toInt()], style: const TextStyle(fontSize: 10))
                    : const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildCanchaChart() {
    return BarChart(
      BarChartData(
        barGroups: _getCanchaReservasData(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final canchas = _filteredReservas.map((r) => r.cancha.nombre).toSet().toList();
                return value.toInt() >= 0 && value.toInt() < canchas.length
                    ? Text(canchas[value.toInt()], style: const TextStyle(fontSize: 10))
                    : const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildHorarioChart() {
    return BarChart(
      BarChartData(
        barGroups: _getHorarioReservasData(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final horas = _filteredReservas.map((r) => r.horario.horaFormateada).toSet().toList();
                return value.toInt() >= 0 && value.toInt() < horas.length
                    ? Text(horas[value.toInt()], style: const TextStyle(fontSize: 10))
                    : const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildTemporalChart() {
    final temporalData = _getReservasTemporalesData();
    final spots = temporalData['spots'] as List<FlSpot>;
    final labels = temporalData['labels'] as List<String>;

    if (spots.isEmpty) {
      return const Center(
        child: Text('No hay datos suficientes para mostrar la gráfica temporal'),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 4, // Aumentado para mayor visibilidad
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5, // Aumentado para destacar puntos
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2), // Área más clara para contraste
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: spots.length > 10 ? (spots.length / 5).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: spots.isNotEmpty
              ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) / 5)
                  .ceilToDouble()
              : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        minX: 0,
        maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 0,
        minY: 0,
        maxY: spots.isNotEmpty
            ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2) // Aumentado para más espacio
            : 10,
      ),
    );
  }
}
