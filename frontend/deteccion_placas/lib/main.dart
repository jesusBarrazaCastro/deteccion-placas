import 'package:deteccion_placas/utilities/confirm_dialog_util.dart';
import 'package:deteccion_placas/utilities/msg_util.dart';
import 'package:deteccion_placas/vehiculo_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // Importante para definir el tipo de contenido
import 'package:permission_handler/permission_handler.dart';

// Importaciones adicionales
import 'api_service.dart';
import 'logs_list.dart'; // Contiene la clase ApiService con el getter baseUrl

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
  // bool _conexionExitosa = false; // Variable no usada, se eliminó

  bool _isLoading = true;
  bool _isProcessing = false;
  int _selectedIndex = 0; // Índice para el BottomNavigationBar

  // Lista para guardar todos los logs
  List<dynamic> _allLogs = [];

  // Lista para mostrar solo los 4 logs más recientes en la pantalla principal
 List<dynamic> _recentLogs = List.generate(
      2,
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

  // Método existente para leer logs (ahora guarda la lista completa y los 4 recientes)
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
        // 1. Guardar TODOS los logs
        _allLogs = response;

        // 2. Calcular contadores
        _totalRegisters = _allLogs.length.toString();
        // Filtrar por logs de hoy. Esto requiere que 'fecha_scan' sea un timestamp válido
        final today = DateTime.now().toIso8601String().substring(0, 10);
        _todayDetections = _allLogs.where((log) => log['fecha_scan']?.toString().startsWith(today) ?? false).length.toString();


        // 3. Obtener los 4 logs más recientes (usando .take(4).toList())
        _recentLogs = _allLogs.take(2).toList();

        // Rellenar con placeholders si hay menos de 4 logs para evitar errores de renderizado
        while (_recentLogs.length < 2) {
          _recentLogs.add({'id': 0, 'placa': '---', 'fecha_scan': '---', 'estado': 'N/A'});
        }


        setState(() {
          _estado = '✅ Consulta exitosa: ${_allLogs.length} logs totales cargados.';
        });
      } else {
        // En caso de respuesta vacía, resetear ambas listas
        _allLogs = [];
        _recentLogs = List.generate(2, (index) => {'id': 0, 'placa': '---', 'fecha_scan': '---', 'estado': 'N/A'});
        throw Exception('Respuesta de API vacía o inválida.');
      }
    } catch (e) {
      setState(() {
        _allLogs = [];
        _recentLogs = List.generate(2, (index) => {'id': 0, 'placa': 'ERROR', 'fecha_scan': 'ERROR', 'estado': 'error'});
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

  // --- Métodos de Navegación ---

  void _openLogsListScreen() {
    // 1. Deseleccionar el BottomNavigationBar temporalmente (opcional, pero mejora UX)
    setState(() {
      _selectedIndex = 0;
    });

    // 2. Navegar a la pantalla de la lista de logs, pasando la lista completa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogsListScreen(
          logs: _allLogs,
          onLogTap: _openManualResultScreen,
        ),
      ),
    ).then((_) {
      // 3. Al regresar, forzamos la recarga de logs (para ver el log recién escaneado)
      _readRecentLogs();
    });
  }

  _openManualResultScreen(Map<String, dynamic> responseData) {
    // Crear el objeto VehiculoData (asumiendo que responseData tiene el formato correcto)
    final vehiculoData = VehiculoData.fromJson(responseData);

    // Navegar a la pantalla de resultados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionResultScreen(
          data: vehiculoData,
        ),
      ),
    ).then((_) {
      // Al cerrar la pantalla de resultado, recargar los logs.
      _readRecentLogs();
    });
  }


  // --- MÉTODOS DE DETECCIÓN DE PLACA (USANDO MULTIPART) ---

  // 1. Método para seleccionar la imagen de la galería
  Future<bool> _checkCameraPermission(BuildContext context) async {
    // 1. Solicitar el permiso. Si ya está concedido, devuelve 'isGranted'.
    final status = await Permission.camera.request();

    if (status.isGranted) {
      // Permiso concedido.
      return true;
    } else if (status.isPermanentlyDenied) {
      // Permiso denegado permanentemente (el usuario marcó "No volver a preguntar").
      // Abrir la configuración del sistema para que el usuario lo active manualmente.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permiso de cámara denegado. Actívalo en Configuración de la App.')
          )
      );
      await openAppSettings();
      return false;
    } else {
      // Permiso denegado por primera vez o restringido.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Se necesita permiso de cámara para escanear la placa.')
          )
      );
      return false;
    }
  }

  void _captureImageAndCallAPI() async {
    if (_isLoading) return; // No permitir acciones mientras carga

    // AÑADIDO: 1. Verificar el permiso de la cámara antes de continuar
    if (!await _checkCameraPermission(context)) {
      // Si el permiso no fue concedido, detenemos la ejecución de la función.
      return;
    }

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
    setState(() {_isProcessing = true;});

    final uri = Uri.parse('${ApiService.baseUrl}/api/vehiculos/detect-plate/');
    var request = http.MultipartRequest('POST', uri);

    try {
      request.fields['AC_type'] = acType;
      // Leer los bytes del archivo (compatible con Web y Móvil)
      final bytes = await imageFile.readAsBytes();
      final mimeTypeString = _getMimeTypeFromFileName(imageFile.name);

      // Crear el MultipartFile usando los bytes y el ContentType explícito
      request.files.add(http.MultipartFile.fromBytes(
        'file', // ¡Debe coincidir con el parámetro 'file' en FastAPI!
        bytes,
        filename: imageFile.name,
        // Usar MediaType para asegurar que el Content-Type se envíe correctamente
        contentType: MediaType.parse(mimeTypeString),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if(responseData['placa_detectada'] == 'AC001'){
          Future.microtask(() {
            ConfirmDialog.error(
                context,
                title: 'No se pudo detectar la placa',
                message: 'Hubo un problema al detectar la placa o no fue encontrada en nuestro sistema, favor de intentarlo nuevamente'
            );
          });
          return; // Terminar la función

        }

        dynamic vehiculoData = responseData['vehiculos_data'][0];
        await _saveScanLog(vehiculoId: vehiculoData['id']);

        setState(() {
          _placaDetectada = vehiculoData['placa'];
        });

        await _openManualResultScreen(vehiculoData);

      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorDetail = errorBody['detail'] ?? 'Error desconocido';
        throw Exception('Fallo la detección (${response.statusCode}): $errorDetail');
      }
    } catch (e) {

      Future.microtask(() {
        ConfirmDialog.error(
            context,
            title: 'Error al detectar la placa',
            message: e.toString()
        );
      });
    }
    finally{
      setState(() {_isProcessing = false;});
    }
  }

  Future<void> _saveScanLog({required int vehiculoId}) async {
    // No cambiamos el estado _isLoading aquí para no interrumpir el flujo visual
    // mientras se muestra la pantalla de resultados.
    try {
      final response = await _apiService.post(
          '/api/logs/write/',
          {'AC': 'save_log', 'vehiculo_id': vehiculoId}
      );

      if (response != null && response is Map && response['status'] == 'ok') {
        // Opcional: Notificación de que el log se guardó
        // MsgtUtil.showSuccess(context, 'Registro de log guardado.');
      } else {
        throw Exception('Respuesta de API inválida al guardar el log.');
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar el log: ${e.toString()}');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      // El 'barrierDismissible: false' es crucial para que el usuario
      // no pueda cerrar el diálogo tocando fuera mientras se procesa la API.
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const PopScope(
          canPop: false, // Evita que se cierre con el botón de retroceso de Android
          child: Dialog(
            // Estilo básico para el diálogo de "Identificando..."
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Identificando placa..."),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // --- WIDGETS AUXILIARES (Skeleton, Card, Record) ---

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

    // No se usa rowBgColor = Colors.white;

    return InkWell(
      onTap: () {
        // Al tocar un registro reciente, mostramos su detalle
        _openManualResultScreen(data);
      },
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
              Icon(Icons.chevron_right, color: primaryColor),
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

    // El cuerpo de la aplicación
    final Widget homeBody = Padding(
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
                // CONEXIÓN DEL BOTÓN "Ver todo"
                onPressed: _openLogsListScreen,
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
    );

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

      // --- 2. Body (Muestra la pantalla de inicio) ---
      body: Stack(
        children: [
          homeBody,
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                // Fondo semi-transparente para indicar que la UI está bloqueada
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 15),
                      Text(
                        "Identificando placa...",
                        style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // --- 3. Barra de Navegación Inferior ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            // CONEXIÓN DEL ITEM 'Historial'
            _openLogsListScreen();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
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