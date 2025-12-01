import 'dart:ui';

import 'package:flutter/material.dart';

// Este widget ahora es Stateful para futuras interacciones como pull-to-refresh
class VehiclesListScreen extends StatefulWidget {
  final List<dynamic> vehicles;
  final Function(Map<String, dynamic>) onVehicleTap;

  const VehiclesListScreen({
    super.key,
    required this.vehicles,
    required this.onVehicleTap,
  });

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {

  // Función auxiliar para determinar el color del estado
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green.shade600;
      case 'inactivo':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Si en el futuro se necesita cargar o refrescar datos
  // internos, la lógica iría aquí, por ejemplo:
  /*
  @override
  void initState() {
    super.initState();
    // Inicializar lógica de la pantalla
  }
  */

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Listado de Vehículos Registrados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: widget.vehicles.isEmpty
                ? const Center(child: Text('No hay vehículos registrados.'))
                : ListView.builder(
              // Usamos widget.vehicles para acceder a los datos pasados al widget
              itemCount: widget.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                final status = vehicle['persona_estado'] ?? 'Desconocido';
                final statusColor = _getStatusColor(status);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.badge, color: Theme.of(context).primaryColor),
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          vehicle['placa'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Spacer(),
                        const Text('Estado: ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        Chip(
                            label: Text(status, style: TextStyle(color: statusColor),),
                            backgroundColor: statusColor.withValues(alpha: 0.4)
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Propietario: ${vehicle['nombre_completo'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                    // Usamos widget.onVehicleTap
                    onTap: () => widget.onVehicleTap(vehicle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}