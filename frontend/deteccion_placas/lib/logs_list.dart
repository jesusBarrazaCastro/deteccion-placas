import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Este es el mismo método de formato de tiempo de MyHomePageState
String _formatTimestamp(String timestamp) {
  if (timestamp == 'Cargando...' || timestamp == 'ERROR' || timestamp == 'N/A' || timestamp == '---') {
    return timestamp;
  }
  try {
    final dateTime = DateTime.parse(timestamp).toLocal();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  } catch (e) {
    return 'Fecha Inválida';
  }
}

class LogsListScreen extends StatelessWidget {
  final List<dynamic> logs;
  final Function(Map<String, dynamic> responseData) onLogTap;

  const LogsListScreen({
    super.key,
    required this.logs,
    required this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: logs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No hay logs registrados todavía.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Listado de escaneos recientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        // Mostramos la lista completa de logs
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                final log = logs[index];

                // Usamos un widget similar al de la pantalla principal
                return _buildListRecord(
                    context,
                    data: log,
                    onTap: () {
                      // Al tocar, navegamos a la pantalla de detalle
                      onLogTap(log);
                    }
                );
                        },
                      ),
              ),
            ],
          ),
    );
  }

  // Widget para construir cada registro de la lista (Similar a _buildRecentRecord)
  Widget _buildListRecord(BuildContext context, {required dynamic data, required VoidCallback onTap}) {
    final primaryColor = Theme.of(context).primaryColor;
    final iconBgColor = primaryColor.withOpacity(0.1);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_car, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['placa'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(data['fecha_scan'] ?? 'N/A'),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}