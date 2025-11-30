import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:deteccion_placas/utilities/msg_util.dart';
import 'api_service.dart';

// Eliminamos la clase 'Incident' y trabajaremos directamente con Map<String, dynamic>

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final ApiService _apiService = ApiService();
  // El Future ahora espera una lista dinámica (que contendrá Map<String, dynamic>)
  late Future<List<dynamic>> _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _fetchIncidents();
  }

  // --- LÓGICA DE OBTENCIÓN DE DATOS ---
  // La función retorna List<dynamic> (lista de JSON crudos)
  Future<List<dynamic>> _fetchIncidents() async {
    try {
      final response = await _apiService.post(
          '/api/vehiculos/read/',
          {'AC': 'get_incidencia_list'}
      );

      if (response is List) {
        return response;
      } else {
        // Simulación: Si la API no devuelve una lista, o es la primera vez,
        // devolvemos datos de ejemplo para que la UI se vea bien.
        return _getDummyIncidents();
      }
    } catch (e) {
      // Mostrar un error en caso de fallo de conexión o del servidor
      if (mounted) {
        MsgtUtil.showError(context, 'Error al cargar incidencias: ${e.toString()}');
      }
      // Retornar datos simulados para evitar que la aplicación se caiga si hay un error
      return _getDummyIncidents();
    }
  }

  // Función de datos de ejemplo (Dummy Data) que retorna Mapas JSON
  List<Map<String, dynamic>> _getDummyIncidents() {
    return [
      {
        'id': 1,
        'placa': 'ABC-123',
        'descripcion': 'Vehículo bloqueando el acceso principal al estacionamiento.',
        'latitud': 24.8080, // Coordenada simulada
        'longitud': -107.4060, // Coordenada simulada
        'registro_fecha': '2023-11-15T10:30:00', // Usamos el formato de string ISO
      },
      {
        'id': 2,
        'placa': 'XYZ-987',
        'descripcion': 'Estacionado en zona de carga y descarga, obstruyendo las operaciones.',
        'latitud': 24.8095,
        'longitud': -107.4085,
        'registro_fecha': '2023-11-16T15:45:00',
      },
      {
        'id': 3,
        'placa': 'MNO-456',
        'descripcion': 'Exceso de velocidad dentro del perímetro de la propiedad.',
        'latitud': 24.8070,
        'longitud': -107.4050,
        'registro_fecha': '2023-11-17T09:00:00',
      },
    ];
  }

  // --- LÓGICA DE UBICACIÓN ---

  // Abre la ubicación de la incidencia en Google Maps o una aplicación de mapas similar.
  Future<void> _openMap(double lat, double lon) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    final uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if(mounted) {
        MsgtUtil.showError(context, 'No se pudo abrir la aplicación de mapas.');
      }
    }
  }

  // --- WIDGET DE LA TARJETA DE INCIDENCIA ---
  // Ahora recibe un mapa de datos crudos
  Widget _buildIncidentCard(Map<String, dynamic> incidentData) {
    // Extracción y manejo de nulls
    final int id = incidentData['id'] ?? 0;
    final String placa = incidentData['placa'] ?? 'N/A';
    final String descripcion = incidentData['descripcion'] ?? 'Sin descripción';
    // Se usa 'num' para manejar el caso de que la API devuelva int o double.
    final double latitud = (incidentData['latitud'] as num?)?.toDouble() ?? 0.0;
    final double longitud = (incidentData['longitud'] as num?)?.toDouble() ?? 0.0;

    // Conversión de fecha de String a DateTime
    final String dateString = incidentData['registro_fecha'] ?? DateTime.now().toIso8601String();
    final DateTime registro_fecha = DateTime.tryParse(dateString) ?? DateTime.now();

    final dateFormat = _getDateFormat(registro_fecha);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placa y Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    placa,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  dateFormat,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),

            // Descripción
            Text(
              'ID: $id - $descripcion',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // Acción: Ubicación
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver Ubicación',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 28),
                  // Se llama a _openMap con los datos extraídos del mapa
                  onPressed: () => _openMap(latitud, longitud),
                  tooltip: 'Abrir en mapa (${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)})',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para formatear la fecha
  String _getDateFormat(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El FutureBuilder espera List<dynamic>
      body: FutureBuilder<List<dynamic>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mostrar indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Mostrar mensaje de error si la carga falla
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Mostrar mensaje si no hay incidencias
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No hay incidencias registradas.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Mostrar la lista de incidencias
            // Casteamos a List<Map<String, dynamic>> para mayor seguridad al iterar
            final incidents = snapshot.data!.cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Listado de Incidencias',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      // Pasamos el mapa JSON directamente al widget de la tarjeta
                      return _buildIncidentCard(incidents[index]);
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      // Botón para refrescar la lista
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _incidentsFuture = _fetchIncidents(); // Recargar datos
          });
          MsgtUtil.showSuccess(context, 'Lista de incidencias actualizada.');
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}