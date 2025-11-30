import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Definición de la estructura de datos del vehículo para la pantalla
class VehiculoData {
  final String placa;
  final String nombreCompleto;
  final String personaTipo;
  final String personaEstado;
  final String correo;
  final String numTelefono;
  final String marca;
  final String modelo;
  final String color;
  final String sexo;
  final String ano;

  VehiculoData({
    required this.placa,
    required this.nombreCompleto,
    required this.personaTipo,
    required this.personaEstado,
    required this.correo,
    required this.numTelefono,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.sexo,
    required this.ano,
  });

  // Constructor factory para parsear el mapa de respuesta de la API
  factory VehiculoData.fromJson(Map<String, dynamic> json) {
    // Aseguramos que los valores sean Strings o manejamos nulos
    final String anoStr = json['ano']?.toString() ?? 'No especificado';

    return VehiculoData(
      placa: json['placa'] ?? 'N/A',
      nombreCompleto: json['nombre_completo'] ?? 'N/A',
      personaTipo: json['persona_tipo'] ?? 'N/A',
      personaEstado: json['persona_estado'] ?? 'N/A',
      correo: json['correo'] ?? 'N/A',
      numTelefono: json['num_telefono'] ?? 'N/A',
      marca: json['marca'] ?? 'N/A',
      modelo: json['modelo'] ?? 'N/A',
      color: json['color'] ?? 'N/A',
      sexo: json['sexo'] ?? 'N/A',
      ano: anoStr,
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL DE RESULTADO
// -----------------------------------------------------------------------------

class DetectionResultScreen extends StatefulWidget {
  final VehiculoData data;

  const DetectionResultScreen({
    super.key,
    required this.data,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {

  // Constantes de color movidas al State
  final Color primaryColor = const Color(0xFF0D47A1); // Azul oscuro
  final Color successColor = const Color(0xFF10B981); // Esmeralda
  final Color accentColor = const Color(0xFF4F46E5); // Indigo

  // --- WIDGET PRINCIPAL BUILD ---

  @override
  Widget build(BuildContext context) {
    // Accedemos a los datos a través de widget.data
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successColor, // Color de éxito
        elevation: 0,
        title: const Text('Resultado de Escaneo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Espacio para el botón fijo
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. Sección de Confirmación y Placa ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              decoration: BoxDecoration(color: successColor),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: successColor, size: 48),
                  ),
                  const SizedBox(height: 10),
                  const Text('Placa Detectada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  const Text('Registro encontrado en la base de datos', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),

            // --- Tarjeta de la Placa (Simulación de Maqueta) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                  border: Border(top: BorderSide(color: accentColor, width: 6)),
                ),
                child: Column(
                  children: [
                    const Text('MÉXICO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      data.placa,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: successColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Verificado', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. Sección de Datos del Propietario ---
            _buildDataCard(
              context,
              title: 'Datos del Propietario',
              icon: Icons.person_outline,
              children: [
                _buildDataRow(Icons.label_outline, 'Nombre Completo', data.nombreCompleto),
                _buildDataRow(Icons.school_outlined, 'Tipo de Persona', data.personaTipo),
                _buildDataRow(Icons.check_circle_outline, 'Estado', data.personaEstado.toUpperCase(),
                  isBadge: true,
                  badgeColor: data.personaEstado.toLowerCase() == 'activo' ? successColor : Colors.red,
                ),
                _buildDataRow(Icons.email_outlined, 'Correo Electrónico', data.correo,
                  isAction: true,
                  onTap: () => launchUrl(Uri.parse('mailto:${data.correo}')),
                ),
                _buildDataRow(Icons.phone_outlined, 'Número de Teléfono', data.numTelefono,
                  isAction: true,
                  onTap: () => launchUrl(Uri.parse('tel:${data.numTelefono}')),
                ),
              ],
            ),

            // --- 3. Sección de Datos del Vehículo ---
            _buildDataCard(
              context,
              title: 'Datos del Vehículo',
              icon: Icons.directions_car_outlined,
              children: [
                _buildGridDetail(context, Icons.car_repair, 'Marca y Modelo', '${data.marca} ${data.modelo}'),
                _buildGridDetail(context, Icons.color_lens_outlined, 'Color', data.color),
                _buildGridDetail(context, Icons.calendar_today_outlined, 'Año', data.ano),
                _buildGridDetail(context, Icons.wc_outlined, 'Género Propietario', data.sexo),
              ],
              isGrid: true,
            ),
          ],
        ),
      ),

      // --- 4. Botón de Acción Crítica (Simulación de Incidencia Manual) ---
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Simular la acción de crear una incidencia.
              // Aquí se podría implementar la lógica de setState() o una llamada a API
              // cuando la funcionalidad esté lista.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulando la creación de una Incidencia Manual.')),
              );
              Navigator.pop(context); // Volver a la pantalla principal
            },
            icon: const Icon(Icons.warning_amber_rounded, size: 24),
            label: const Text(
              'Crear Incidencia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 5,
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Movidos al State) ---

  Widget _buildDataCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
        bool isGrid = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 24),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 20),
              if (isGrid)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                  children: children,
                )
              else
                ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
      IconData icon,
      String title,
      String value, {
        bool isAction = false,
        VoidCallback? onTap,
        bool isBadge = false,
        Color badgeColor = Colors.grey,
      }) {
    return InkWell(
      onTap: isAction ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 3),
                  if (isBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isAction ? primaryColor : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isAction) Icon(Icons.chevron_right, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDetail(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: 17),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}