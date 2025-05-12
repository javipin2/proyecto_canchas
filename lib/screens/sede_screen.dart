import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../providers/sede_provider.dart';
import 'canchas_screen.dart';
import 'admin/admin_login_screen.dart';

class SedeScreen extends StatefulWidget {
  const SedeScreen({super.key});

  @override
  State<SedeScreen> createState() => _SedeScreenState();
}

class _SedeScreenState extends State<SedeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final List<Animation<double>> _buttonScales = [];

  @override
  void initState() {
    super.initState();

    // Configuración de la barra de estado para estética minimalista
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Configuración principal de animaciones
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    // Creamos animaciones de escala para cada uno de los tres botones (Sede 1, Sede 2 y Administración)
    for (int i = 0; i < 3; i++) {
      _buttonScales.add(
        Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0.3 + (i * 0.1), 0.7 + (i * 0.1),
                curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    // Iniciamos las animaciones con un pequeño retraso
    Future.delayed(const Duration(milliseconds: 50), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Método para manejar la selección de sede con efecto háptico y animación
  void _seleccionarSede(BuildContext context, String sede) async {
    HapticFeedback.lightImpact();
    print('📌 Seleccionando $sede...');
    await Provider.of<SedeProvider>(context, listen: false).setSede(sede);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CanchasScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation =
              CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // AppBar minimalista sin contenido para dejar ver el fondo
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo minimalista con degradado sutil y patrón decorativo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Patrones decorativos sutiles pintados sobre el fondo
          Positioned.fill(
            child: FadeTransition(
              opacity: Animation<double>.fromValueListenable(
                ValueNotifier(_fadeAnimation.value * 0.4),
              ),
              child: CustomPaint(
                painter: MinimalistPatternPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          // Contenido principal dentro de SafeArea
          SafeArea(
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo con animación de desvanecimiento
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Image.asset(
                            'assets/img1.png',
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.sports_tennis,
                                  size: 70, color: Colors.black87);
                            },
                          ),
                        ),
                      ),
                      // Título principal
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Selecciona una sede',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Para comenzar tu reserva',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Botón de Sede 1 (Card con animación de escala y efecto Hero)
                      ScaleTransition(
                        scale: _buttonScales[0],
                        child: Hero(
                          tag: "sede_1",
                          child: _buildSedeButton(
                            context,
                            'Sede 1',
                            const Color(0xFF303030),
                            Icons.place_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Botón de Sede 2 (Card similar a Sede1)
                      ScaleTransition(
                        scale: _buttonScales[1],
                        child: Hero(
                          tag: "sede_2",
                          child: _buildSedeButton(
                            context,
                            'Sede 2',
                            const Color(0xFF505050),
                            Icons.place_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Botón de Administración, con animación de escala
                      ScaleTransition(
                        scale: _buttonScales[2],
                        child: _buildAdminButton(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Método para construir un botón (card) de selección de sede con un diseño minimalista y animado
  Widget _buildSedeButton(
      BuildContext context, String sede, Color color, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10 * value,
                offset: Offset(0, 4 * value),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _seleccionarSede(context, sede),
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.grey.withOpacity(0.1),
              highlightColor: Colors.grey.withOpacity(0.05),
              child: MouseRegion(
                onEnter: (_) => setState(() {}), // efecto hover en web
                onExit: (_) => setState(() {}),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              color: color,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              sede,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: color,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Botón de administración con diseño minimalista y animación de desvanecimiento
  Widget _buildAdminButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03 * value),
                blurRadius: 6 * value,
                offset: Offset(0, 2 * value),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.grey.withOpacity(0.1),
              highlightColor: Colors.grey.withOpacity(0.05),
              child: MouseRegion(
                onEnter: (_) => setState(() {}), // efecto hover en web
                onExit: (_) => setState(() {}),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Administración',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Clase para dibujar un patrón minimalista en el fondo
class MinimalistPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Dibujamos formas sutiles para decorar el fondo
    _drawRoundedRect(canvas, paint, size.width * 0.15, size.height * 0.2,
        size.width * 0.25, size.height * 0.15);
    _drawRoundedRect(canvas, paint, size.width * 0.7, size.height * 0.3,
        size.width * 0.4, size.height * 0.2);
    _drawRoundedRect(canvas, paint, size.width * 0.1, size.height * 0.75,
        size.width * 0.3, size.height * 0.1);
    _drawCircle(
        canvas, paint, size.width * 0.8, size.height * 0.8, size.width * 0.15);
  }

  void _drawRoundedRect(Canvas canvas, Paint paint, double x, double y,
      double width, double height) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(20),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawCircle(
      Canvas canvas, Paint paint, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
