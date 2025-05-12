import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Asegúrate de crear (o tener) estos archivos en la carpeta lib/screens/admin/
import 'clientes/clientes_screen.dart'; // Pantalla de gestión de clientes
import 'canchas/canchas_screen.dart'; // Pantalla de gestión de sedes y canchas
import 'graficas/graficas_screen.dart'; // Pantalla de notificaciones
import 'reservas/admin_reservas_horarios_screen.dart'; // Pantalla de gestión de reservas

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context); // Regresa al screen anterior (por ejemplo, login)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                "Menú Principal",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Clientes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClientesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text("Sedes y Canchas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CanchasScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notificaciones"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GraficasScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text("Reservas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const AdminReservasHorariosScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isDesktop ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAdminCard(
                  icon: Icons.people,
                  title: "Ver Clientes",
                  description: "Consulta y gestiona clientes registrados.",
                  color: Colors.blue,
                  context: context,
                  screen: const ClientesScreen(),
                ),
                _buildAdminCard(
                  icon: Icons.business,
                  title: "Sedes y Canchas",
                  description: "Administra sedes y asigna canchas.",
                  color: Colors.orange,
                  context: context,
                  screen: const CanchasScreen(),
                ),
                _buildAdminCard(
                  icon: Icons.notifications_active,
                  title: "Notificaciones",
                  description: "Revisa alertas y mensajes importantes.",
                  color: Colors.red,
                  context: context,
                  screen: const GraficasScreen(),
                ),
                _buildAdminCard(
                  icon: Icons.schedule,
                  title: "Reservas",
                  description: "Gestiona horarios disponibles.",
                  color: Colors.green,
                  context: context,
                  screen: const AdminReservasHorariosScreen(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required BuildContext context,
    required Widget screen,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
