import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/reserva.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({super.key});

  @override
  GraficasScreenState createState() => GraficasScreenState();
}

class GraficasScreenState extends State<GraficasScreen> {
  DateTime? _selectedDate;
  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  bool _isLoading = false;
  String _filterType = 'Mes'; // Día, Semana, Mes

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .get()
          .timeout(const Duration(seconds: 10));

      _reservas =
          querySnapshot.docs.map((doc) => Reserva.fromFirestore(doc)).toList();
      _filteredReservas = _reservas;
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
    if (_selectedDate == null) {
      setState(() => _filteredReservas = _reservas);
      return;
    }

    List<Reserva> filtered = _reservas;
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
    setState(() => _filteredReservas = filtered);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  List<PieChartSectionData> _getConfirmationData() {
    final confirmadas = _filteredReservas.where((r) => r.confirmada).length;
    final noConfirmadas = _filteredReservas.length - confirmadas;
    return [
      PieChartSectionData(
        value: confirmadas.toDouble(),
        color: Colors.green,
        title: '$confirmadas',
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: noConfirmadas.toDouble(),
        color: Colors.red,
        title: '$noConfirmadas',
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  List<BarChartGroupData> _getSedeSalesData() {
    final sedes = _filteredReservas.map((r) => r.sede).toSet();
    return sedes.map((sede) {
      final total = _filteredReservas
          .where((r) => r.sede == sede)
          .fold(0.0, (sum, r) => sum + r.montoPagado);
      return BarChartGroupData(
        x: sedes.toList().indexOf(sede),
        barRods: [
          BarChartRodData(
            toY: total,
            color: Colors.blueAccent,
            width: 20,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  List<BarChartGroupData> _getCanchaData() {
    final canchas = _filteredReservas.map((r) => r.cancha.nombre).toSet();
    return canchas.map((cancha) {
      final count = _filteredReservas
          .where((r) => r.cancha.nombre == cancha)
          .length
          .toDouble();
      return BarChartGroupData(
        x: canchas.toList().indexOf(cancha),
        barRods: [
          BarChartRodData(
            toY: count,
            color: Colors.orangeAccent,
            width: 20,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  List<BarChartGroupData> _getHoraData() {
    final horas =
        _filteredReservas.map((r) => r.horario.hora.hour.toString()).toSet();
    return horas.map((hora) {
      final count = _filteredReservas
          .where((r) => r.horario.hora.hour.toString() == hora)
          .length
          .toDouble();
      return BarChartGroupData(
        x: horas.toList().indexOf(hora),
        barRods: [
          BarChartRodData(
            toY: count,
            color: Colors.purpleAccent,
            width: 20,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  List<LineChartBarData> _getMonthlySalesData() {
    final monthlySales = <DateTime, double>{};
    for (var reserva in _filteredReservas) {
      final month = DateTime(reserva.fecha.year, reserva.fecha.month);
      monthlySales[month] = (monthlySales[month] ?? 0) + reserva.montoPagado;
    }
    final sortedKeys = monthlySales.keys.toList()..sort();
    return [
      LineChartBarData(
        spots: sortedKeys.map((month) {
          return FlSpot(
            month.millisecondsSinceEpoch.toDouble(),
            monthlySales[month]!,
          );
        }).toList(),
        isCurved: true,
        color: Colors.blueAccent,
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalVentas =
        _filteredReservas.fold(0.0, (sum, r) => sum + r.montoPagado);
    final reservasConfirmadas =
        _filteredReservas.where((r) => r.confirmada).length;
    final reservasTotales = _filteredReservas.length;
    final canchaMasPedida = _filteredReservas.isNotEmpty
        ? _filteredReservas
            .map((r) => r.cancha.nombre)
            .toList()
            .fold<Map<String, int>>({}, (map, cancha) {
              map[cancha] = (map[cancha] ?? 0) + 1;
              return map;
            })
            .entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'N/A';
    final sedeMasPedida = _filteredReservas.isNotEmpty
        ? _filteredReservas
            .map((r) => r.sede)
            .toList()
            .fold<Map<String, int>>({}, (map, sede) {
              map[sede] = (map[sede] ?? 0) + 1;
              return map;
            })
            .entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Análisis de Reservas"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Filtros
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _filterType,
                              onChanged: (value) {
                                setState(() {
                                  _filterType = value!;
                                  _applyFilters();
                                });
                              },
                              items: ['Día', 'Semana', 'Mes']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                _selectedDate == null
                                    ? 'Todos los datos'
                                    : _filterType == 'Día'
                                        ? DateFormat('dd MMMM yyyy', 'es')
                                            .format(_selectedDate!)
                                        : _filterType == 'Semana'
                                            ? 'Semana del ${DateFormat('dd MMMM yyyy', 'es').format(_selectedDate!.subtract(Duration(days: _selectedDate!.weekday - 1)))}'
                                            : DateFormat('MMMM yyyy', 'es')
                                                .format(_selectedDate!),
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Métricas clave
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard(
                          'Total Ingresos',
                          '\$${totalVentas.toStringAsFixed(2)}',
                          Colors.blueAccent),
                      _buildMetricCard(
                          'Reservas Confirmadas',
                          '$reservasConfirmadas/$reservasTotales',
                          Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard('Cancha Más Pedida', canchaMasPedida,
                          Colors.orangeAccent),
                      _buildMetricCard('Sede Más Pedida', sedeMasPedida,
                          Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Gráficos
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildChartSection(
                            title: 'Ingresos por Sede',
                            chart: BarChart(
                              BarChartData(
                                barGroups: _getSedeSalesData(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final sedes = _filteredReservas
                                            .map((r) => r.sede)
                                            .toSet()
                                            .toList();
                                        return Text(
                                          sedes[value.toInt()] ?? '',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 40),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: const FlGridData(show: true),
                              ),
                            ),
                          ),
                          _buildChartSection(
                            title: 'Reservas por Estado',
                            chart: PieChart(
                              PieChartData(
                                sections: _getConfirmationData(),
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          _buildChartSection(
                            title: 'Canchas Más Reservadas',
                            chart: BarChart(
                              BarChartData(
                                barGroups: _getCanchaData(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final canchas = _filteredReservas
                                            .map((r) => r.cancha.nombre)
                                            .toSet()
                                            .toList();
                                        return Text(
                                          canchas[value.toInt()] ?? '',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 40),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: const FlGridData(show: true),
                              ),
                            ),
                          ),
                          _buildChartSection(
                            title: 'Horas Más Reservadas',
                            chart: BarChart(
                              BarChartData(
                                barGroups: _getHoraData(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final horas = _filteredReservas
                                            .map((r) =>
                                                r.horario.hora.hour.toString())
                                            .toSet()
                                            .toList();
                                        return Text(
                                          '${horas[value.toInt()]}:00',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 40),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: const FlGridData(show: true),
                              ),
                            ),
                          ),
                          _buildChartSection(
                            title: 'Ingresos Mensuales',
                            chart: LineChart(
                              LineChartData(
                                lineBarsData: _getMonthlySalesData(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final date =
                                            DateTime.fromMillisecondsSinceEpoch(
                                                value.toInt());
                                        return Text(
                                          DateFormat('MMM yy').format(date),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 40),
                                  ),
                                ),
                                gridData: const FlGridData(show: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget chart}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
