import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reserva_canchas/models/cancha.dart';
import 'editar_cancha_screen.dart';
import 'registrar_cancha_screen.dart';
import '../admin_dashboard_screen.dart';

class CanchasScreen extends StatefulWidget {
  const CanchasScreen({super.key});

  @override
  CanchasScreenState createState() => CanchasScreenState();
}

class CanchasScreenState extends State<CanchasScreen> {
  String _selectedSede = "";
  final Color _primaryColor = const Color(0xFF3C4043);
  final Color _secondaryColor = const Color(0xFF4285F4);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = const Color(0xFFF8F9FA);

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('canchas');
    if (_selectedSede.isNotEmpty) {
      query = query.where('sede', isEqualTo: _selectedSede);
    }
    return query;
  }

  Future<void> _eliminarCancha(String canchaId, BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Confirmar eliminación',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar esta cancha?',
          style: GoogleFonts.montserrat(color: _primaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(color: _secondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.montserrat(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('canchas')
            .doc(canchaId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cancha eliminada correctamente',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: _secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $error',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth >= 500 && screenWidth <= 900;
    final textScale = screenWidth < 500 ? 0.9 : (isTablet ? 1.0 : 1.1);
    final paddingScale = screenWidth < 500 ? 8.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Canchas',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: _primaryColor,
            fontSize: 20 * textScale,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: _secondaryColor, size: 24 * textScale),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen()),
            );
          },
          tooltip: 'Volver al Dashboard',
        ),
      ),
      body: Container(
        color: _backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(paddingScale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lista de Canchas',
                    style: GoogleFonts.montserrat(
                      fontSize: 24 * textScale,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegistrarCanchaScreen()),
                      );
                    },
                    icon: Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 20 * textScale),
                    label: Text(
                      'Nueva Cancha',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16 * textScale,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20 * textScale, vertical: 12 * textScale),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: paddingScale),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _cardColor),
                ),
                color: _cardColor,
                child: Padding(
                  padding: EdgeInsets.all(paddingScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtros',
                        style: GoogleFonts.montserrat(
                          fontSize: 18 * textScale,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: paddingScale),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('canchas')
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Depuración
                          print(
                              'Estado de conexión (canchas): ${snapshot.connectionState}');
                          print('Tiene datos: ${snapshot.hasData}');
                          print(
                              'Número de documentos: ${snapshot.data?.docs.length}');
                          if (snapshot.hasError) {
                            return Padding(
                              padding: EdgeInsets.all(paddingScale),
                              child: Text(
                                'Error al cargar datos: ${snapshot.error}',
                                style: GoogleFonts.montserrat(
                                  color: Colors.redAccent,
                                  fontSize: 14 * textScale,
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _secondaryColor),
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(paddingScale),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No hay canchas disponibles',
                                    style: GoogleFonts.montserrat(
                                      color: _primaryColor,
                                      fontSize: 14 * textScale,
                                    ),
                                  ),
                                  Text(
                                    'Por favor, agrega canchas en Firestore.',
                                    style: GoogleFonts.montserrat(
                                      color: _primaryColor.withOpacity(0.7),
                                      fontSize: 12 * textScale,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Extraer valores únicos del campo 'sede' desde 'canchas'
                          final canchaDocs = snapshot.data!.docs;
                          final sedesSet = <String>{};
                          for (var doc in canchaDocs) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final sede = data['sede']?.toString();
                            if (sede != null && sede.isNotEmpty) {
                              sedesSet.add(sede);
                            }
                          }
                          final sedes = [
                            'Todas las sedes',
                            ...sedesSet.toList()..sort(),
                          ];
                          if (sedes.length == 1) {
                            return Padding(
                              padding: EdgeInsets.all(paddingScale),
                              child: Text(
                                'No hay sedes válidas en las canchas. Revisa los datos en Firestore.',
                                style: GoogleFonts.montserrat(
                                  color: Colors.redAccent,
                                  fontSize: 14 * textScale,
                                ),
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Filtrar por Sede',
                              labelStyle:
                                  GoogleFonts.montserrat(color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _cardColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _cardColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _secondaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16 * textScale,
                                  vertical: 16 * textScale),
                            ),
                            value:
                                _selectedSede.isNotEmpty ? _selectedSede : null,
                            hint: Text(
                              'Selecciona una sede',
                              style:
                                  GoogleFonts.montserrat(color: _primaryColor),
                            ),
                            items: sedes
                                .map((sede) => DropdownMenuItem(
                                      value:
                                          sede == 'Todas las sedes' ? '' : sede,
                                      child: Text(
                                        sede,
                                        style: GoogleFonts.montserrat(
                                            color: _primaryColor),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSede = value ?? '';
                                print('Sede seleccionada: $_selectedSede');
                              });
                            },
                            icon: Icon(Icons.arrow_drop_down,
                                color: _primaryColor),
                            isExpanded: true,
                            dropdownColor: _backgroundColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: paddingScale),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildQuery().snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 60 * textScale),
                            SizedBox(height: paddingScale),
                            Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.montserrat(
                                  color: Colors.redAccent,
                                  fontSize: 16 * textScale),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_secondaryColor),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_soccer,
                                color: _primaryColor.withOpacity(0.5),
                                size: 70 * textScale),
                            SizedBox(height: paddingScale),
                            Text(
                              'No se encontraron canchas',
                              style: GoogleFonts.montserrat(
                                fontSize: 18 * textScale,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Intenta con otro filtro o registra una nueva cancha',
                              style: GoogleFonts.montserrat(
                                fontSize: 14 * textScale,
                                color: _primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final canchaDocs = snapshot.data!.docs;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return (isDesktop || isTablet)
                            ? _buildDataTable(
                                canchaDocs, constraints.maxWidth, textScale)
                            : _buildListView(canchaDocs, textScale);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> canchaDocs,
      double maxWidth, double textScale) {
    final columnWidth = maxWidth / 6.5;
    final minColumnWidth = 100.0;
    final maxColumnWidth = columnWidth.clamp(minColumnWidth, 200.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _cardColor),
      ),
      color: _cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: maxWidth),
          child: DataTable(
            columnSpacing: 8,
            headingRowHeight: 56 * textScale,
            dataRowMinHeight: 60 * textScale,
            dataRowMaxHeight: 60 * textScale,
            headingTextStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: _primaryColor,
              fontSize: 14 * textScale,
            ),
            dataTextStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: _primaryColor,
              fontSize: 13 * textScale,
            ),
            columns: [
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth * 0.8,
                  child: Text('ID', overflow: TextOverflow.ellipsis),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth,
                  child: Text('Nombre', overflow: TextOverflow.ellipsis),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth,
                  child: Text('Sede', overflow: TextOverflow.ellipsis),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth,
                  child: Text('Descripción', overflow: TextOverflow.ellipsis),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth * 0.8,
                  child: Text('Precio', overflow: TextOverflow.ellipsis),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: maxColumnWidth * 0.8,
                  child: Text('Acciones', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            rows: canchaDocs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    return index % 2 == 0 ? _cardColor : _backgroundColor;
                  },
                ),
                cells: [
                  DataCell(
                    SizedBox(
                      width: maxColumnWidth * 0.8,
                      child: Text(
                        doc.id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: maxColumnWidth,
                      child: Text(
                        data['nombre']?.toString() ?? 'N/A',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: maxColumnWidth,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8 * textScale, vertical: 4 * textScale),
                        decoration: BoxDecoration(
                          color: _secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _secondaryColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          data['sede']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: _secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: maxColumnWidth,
                      child: Text(
                        data['descripcion']?.toString() ?? 'N/A',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: maxColumnWidth * 0.8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8 * textScale, vertical: 4 * textScale),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Text(
                          '\$${data['precio']?.toString() ?? 'N/A'}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Editar cancha',
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: _secondaryColor,
                              size: 20 * textScale,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarCanchaScreen(
                                    canchaId: doc.id,
                                    cancha: Cancha.fromFirestore(
                                        doc), // Usar el modelo Cancha
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'Eliminar cancha',
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20 * textScale,
                            ),
                            onPressed: () => _eliminarCancha(doc.id, context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
      List<QueryDocumentSnapshot> canchaDocs, double textScale) {
    return ListView.builder(
      itemCount: canchaDocs.length,
      itemBuilder: (context, index) {
        final doc = canchaDocs[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _cardColor),
          ),
          color: _cardColor,
          margin: EdgeInsets.only(bottom: 12 * textScale),
          child: ListTile(
            contentPadding: EdgeInsets.all(12 * textScale),
            title: Text(
              data['nombre']?.toString() ?? 'N/A',
              style: GoogleFonts.montserrat(
                fontSize: 16 * textScale,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4 * textScale),
                Text(
                  'Sede: ${data['sede']?.toString() ?? 'N/A'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14 * textScale,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Descripción: ${data['descripcion']?.toString() ?? 'N/A'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14 * textScale,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Precio: \$${data['precio']?.toString() ?? 'N/A'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14 * textScale,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: _secondaryColor,
                    size: 20 * textScale,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditarCanchaScreen(
                          canchaId: doc.id,
                          cancha: Cancha.fromFirestore(
                              doc), // Usar el modelo Cancha
                        ),
                      ),
                    );
                  },
                  tooltip: 'Editar cancha',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20 * textScale,
                  ),
                  onPressed: () => _eliminarCancha(doc.id, context),
                  tooltip: 'Eliminar cancha',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
