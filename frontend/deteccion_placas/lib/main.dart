import 'package:deteccion_placas/utilities/confirm_dialog_util.dart';
import 'package:deteccion_placas/utilities/msg_util.dart';
import 'package:deteccion_placas/vehiculo_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // Importante para definir el tipo de contenido

// Asegúrate de que este archivo exista en tu proyecto.
import 'api_service.dart'; // Contiene la clase ApiService con el getter baseUrl

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);

    return MaterialApp(
      title: 'Detección de Placas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Detección de Placas'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // --- VARIABLES DE ESTADO ---
  final ApiService _apiService = ApiService();
  String _estado = 'Iniciando...';
  bool _conexionExitosa = false;

  bool _isLoading = true;

  List<dynamic> _recentLogs = List.generate(
      4,
          (index) => {
        'id': 0,
        'placa': 'Cargando...',
        'fecha_scan': 'Cargando...',
        'estado': 'ok',
      }
  );

  String _totalRegisters = '...';
  String _todayDetections = '...';

  String _placaDetectada = 'Esperando imagen...';
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _readRecentLogs();
  }

  // --- MÉTODOS DE UTILIDAD ---

  // Nuevo método para inferir el tipo de imagen del nombre del archivo
  String _getMimeTypeFromFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.png')) {
      return 'image/png';
    } else if (fileName.toLowerCase().endsWith('.gif')) {
      return 'image/gif';
    }
    // Default a JPEG si no se reconoce o es el tipo más común
    return 'image/jpeg';
  }


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

  // --- MÉTODOS DE API ---

  // Método existente para leer logs (usa _apiService.post - JSON)
  Future<void> _readRecentLogs() async {
    setState(() {
      _isLoading = true;
      _estado = '🔍 Consultando registros...';
    });

    try {
      final response = await _apiService.post(
          '/api/vehiculos/read/',
          {'AC': 'get_logs'}
      );

      if (response != null && response is List && response.isNotEmpty) {
        _totalRegisters = response.length.toString();
        _todayDetections = response.where((log) => log['fecha_scan']?.contains(DateTime.now().year.toString()) ?? false).length.toString();

        _recentLogs = response;

        if(_recentLogs.length > 4){
          _recentLogs = _recentLogs.take(4).toList();
        }

        setState(() {
          _estado = '✅ Consulta exitosa: ${_recentLogs.length} logs cargados.';
        });
      } else {
        throw Exception('Respuesta de API vacía o inválida.');
      }
    } catch (e) {
      setState(() {
        _recentLogs = List.generate(4, (index) => {'placa': 'ERROR', 'fecha_scan': 'ERROR', 'estado': 'error'});
        _totalRegisters = '---';
        _todayDetections = '---';
        _estado = '❌ Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MÉTODOS DE DETECCIÓN DE PLACA (USANDO MULTIPART) ---

  // 1. Método para seleccionar la imagen de la galería
  void _captureImageAndCallAPI() async {
    if (_isLoading) return; // No permitir acciones mientras carga

    final ImagePicker picker = ImagePicker();

    // Capturar la imagen usando la fuente de la cámara
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      try {
        // El tipo de acción AC_type para la cámara
        const String acType = "by_id";

        // Reutilizar el método de envío a la API
        await _callPlateDetectionAPI(image, acType);

      } catch (e) {
        print("Error en _captureImageAndCallAPI: $e");
        // Mostrar un mensaje de error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la imagen de la cámara: $e'))
        );
      }
    } else {
      print("Captura de imagen cancelada.");
    }
  }

  void _selectImageAndCallAPI() async {
    if (_isLoading) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        const String acType = "by_id";
        await _callPlateDetectionAPI(image, acType);

      } catch (e) {
        print("Error en _selectImageAndCallAPI: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la imagen: ${e.toString()}'))
        );
      }
    } else {
      print("Selección de imagen cancelada.");
    }
  }

  Future<void> _callPlateDetectionAPI(XFile imageFile, String acType) async {
    setState(() {
      _isLoading = true;
      _placaDetectada = 'Detectando placa...';
    });

    final uri = Uri.parse('${ApiService.baseUrl}/api/vehiculos/detect-plate/');
    var request = http.MultipartRequest('POST', uri);

    try {
      // Añadir el campo de formulario AC_type
      request.fields['AC_type'] = acType;

      // Leer los bytes del archivo (compatible con Web y Móvil)
      final bytes = await imageFile.readAsBytes();

      // --- FIX APLICADO AQUÍ ---
      final mimeTypeString = _getMimeTypeFromFileName(imageFile.name);

      // Crear el MultipartFile usando los bytes y el ContentType explícito
      request.files.add(http.MultipartFile.fromBytes(
        'file', // ¡Debe coincidir con el parámetro 'file' en FastAPI!
        bytes,
        filename: imageFile.name,
        // Usar MediaType para asegurar que el Content-Type se envíe correctamente
        contentType: MediaType.parse(mimeTypeString),
      ));
      // --- FIN DEL FIX ---

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final placa = responseData['placa_detectada'] ?? 'PLACA NO ENCONTRADA';

        if(responseData['placa_detectada'] == 'AC001'){
          ConfirmDialog.error(
              context,
              title: 'No se pudo detectar la placa',
              message: 'Intente de nuevo'
          );
          return;
        }
        dynamic vehiculoData = responseData['vehiculos_data'][0]; //GUARDAR EN UNA VARIABLE LOS DATOS RECIBIDOS DEL VEHICULO
        await _saveScanLog(vehiculoId: vehiculoData['id']); //GUARDAR EN LOS LOGS DE SCANEO
        _openManualResultScreen(responseData: vehiculoData);//DESPLEGAR LOS RESULTADOS DE LA BUSQUEDA
        setState(() {});

      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorDetail = errorBody['detail'] ?? 'Error desconocido';
        throw Exception('Fallo la detección (${response.statusCode}): $errorDetail');
      }
    } catch (e) {
      ConfirmDialog.error(
          context,
          title: 'Error al detectar la placa',
          message: e.toString()
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveScanLog({required int vehiculoId}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.post(
          '/api/logs/write/',
          {'AC': 'save_log', 'vehiculo_id': vehiculoId}
      );

      if (response != null && response is List && response.isNotEmpty) {

      } else {
        throw Exception('Respuesta de API vacía o inválida.');
      }
    } catch (e) {
        MsgtUtil.showError(context, 'Error al guardar el log: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openManualResultScreen({required Map<String, dynamic> responseData}) {
    // Crear el objeto VehiculoData
    final vehiculoData = VehiculoData.fromJson(responseData);

    // Navegar a la pantalla de resultados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionResultScreen(
          data: vehiculoData,
        ),
      ),
    );

  }


  // --- WIDGETS AUXILIARES (Skeleton, Card, Record) (Sin Cambios) ---

  Widget _buildSkeleton({required double height, double width = double.infinity, double radius = 8.0}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: _buildSkeleton(height: 60, width: double.infinity, radius: 15),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildCounterCard(BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 15),
          if (_isLoading)
            _buildSkeleton(height: 24, width: 60, radius: 4)
          else
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecord({dynamic data}) {
    final primaryColor = Theme.of(context).primaryColor;
    final iconBgColor = primaryColor.withOpacity(0.1);

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSkeleton(height: 44, width: 44, radius: 8),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeleton(height: 18, width: 120, radius: 4),
                  const SizedBox(height: 8),
                  _buildSkeleton(height: 14, width: 150, radius: 4),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Color rowBgColor = Colors.white;

    return InkWell(
      onTap: () {
        _openManualResultScreen(responseData: data);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            //color: rowBgColor,
            borderRadius: BorderRadius.circular(12),
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
                      data['placa']??'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(data['fecha_scan'])??'N/A',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET PRINCIPAL BUILD ---

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Colors.grey.shade700;

    return Scaffold(
      // --- 1. AppBar ---
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10,),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detección de Placas', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                SizedBox(height: 3,),
                Text('Registro de incidencias', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.3),
                child: const Icon(Icons.notifications, color: Colors.black)
            ),
          ),
        ],
      ),

      // --- 2. Body (SingleChildScrollView con Column) ---
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),

            // --- Tarjetas de Contadores ---
            Row(
              children: [
                Expanded(
                  child: _buildCounterCard(
                    context,
                    icon: Icons.description,
                    count: _totalRegisters,
                    label: 'Registros totales',
                    backgroundColor: const Color(0xFFE3F2FD),
                    iconColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildCounterCard(
                    context,
                    icon: Icons.calendar_today,
                    count: _todayDetections,
                    label: 'Hoy detectadas',
                    backgroundColor: const Color(0xFFE8F5E9),
                    iconColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Encabezado 'Recientes' ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recientes',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () { /* Acción de ver todo */ },
                  child: Text(
                    'Ver todo',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- Lista de 4 Registros Recientes ---
            ..._recentLogs.map((log) => _buildRecentRecord(data: log)).toList(),

            const SizedBox(height: 40),

            // --- Botones de Acción Apilados (Seleccionar Imagen - Arriba) ---
            _buildActionButton(
              label: 'Seleccionar Imagen',
              icon: Icons.photo_library,
              color: secondaryColor,
              onPressed: _selectImageAndCallAPI, // Conectado al método de detección
            ),
            const SizedBox(height: 10),

            // --- Botones de Acción Apilados (Escanear Placa - Abajo) ---
            Expanded(
              child: _buildActionButton(
                label: 'Escanear Placa',
                icon: Icons.camera_alt,
                color: primaryColor,
                onPressed: _captureImageAndCallAPI,
              ),
            ),
          ],
        ),
      ),

      // --- 3. Barra de Navegación Inferior ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}