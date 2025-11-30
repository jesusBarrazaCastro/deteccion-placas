import 'package:deteccion_placas/utilities/msg_util.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'api_service.dart';
import 'package:geolocator/geolocator.dart'; // AÑADIDO: Para obtener la ubicación

// Definición de las opciones de estado de la incidencia
enum IncidentStatus { aviso, infraccionGrave, bloqueoAcceso }

class IncidentFormScreen extends StatefulWidget {
  // Recibe los datos del vehículo como un mapa JSON.
  final Map<String, dynamic> vehicleJsonData;

  const IncidentFormScreen({super.key, required this.vehicleJsonData});

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  static const int maxDescriptionLength = 500; // Límite de caracteres

  // Estado del formulario
  IncidentStatus? _selectedStatus;
  List<XFile> _additionalImages = []; // Almacena las XFile de la evidencia
  bool _isSaving = false;

  // ESTADO DE UBICACIÓN (AÑADIDO)
  bool _isLocationLoading = true;
  Position? _currentPosition;
  String? _locationError;


  @override
  void initState() {
    super.initState();
    // Obtener la ubicación inmediatamente al cargar la pantalla
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Comprueba si el botón de registro debe estar habilitado
  bool get _isFormValid => _descriptionController.text.length >= 10 && _currentPosition != null; // Requiere ubicación válida

  // --- LÓGICA DE GEOLOCALIZACIÓN (AÑADIDO) ---

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Los servicios de ubicación están deshabilitados. Por favor, habilítelos.';
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Permiso de ubicación denegado por el usuario.';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError = 'El permiso de ubicación fue denegado permanentemente. No se puede acceder.';
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) {
      setState(() {
        _isLocationLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener la ubicación: ${e.toString()}';
        _isLocationLoading = false;
      });
    }
  }

  // Lógica para añadir imágenes
  Future<void> _addEvidenceImage() async {
    if (_additionalImages.length >= 3) {
      MsgtUtil.showWarning(context, 'Solo se permiten un máximo de 3 imágenes de evidencia.');
      return;
    }

    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          final remainingSlots = 3 - _additionalImages.length;
          _additionalImages.addAll(pickedFiles.take(remainingSlots));
        });
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al seleccionar imagen: $e');
    }
  }

  // Lógica para eliminar imagen
  void _removeEvidenceImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  // Lógica de Registro de Incidencia
  void _registerIncident() async {
    if (!_isFormValid) {
      MsgtUtil.showWarning(context, 'Por favor, complete la descripción, seleccione el tipo de incidencia y obtenga la ubicación.');
      return;
    }

    if (_currentPosition == null) {
      MsgtUtil.showWarning(context, 'No se pudo obtener la ubicación. Por favor, intente de nuevo.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Simulación/Lógica de subida de imágenes para obtener URLs
      final List<String> uploadedImageUrls = _additionalImages.map((xfile) => 'url_storage_simulada/${xfile.name}').toList();

      // 2. Obtener datos clave
      final int vehiculoId = widget.vehicleJsonData['id'] ?? 0;
      final String placa = widget.vehicleJsonData['placa'] ?? 'N/A';

      // Construir el payload que coincide con el SP 'register_incident'
      final Map<String, dynamic> incidentPayload = {
        'vehiculo_id': vehiculoId,
        'placa': placa,
        'descripcion': _descriptionController.text,
        'latitud': _currentPosition!.latitude,   // Coordenada Latitud
        'longitud': _currentPosition!.longitude, // Coordenada Longitud
        //'imagenes_urls': uploadedImageUrls,
      };

      // guardar
      await _save(data: incidentPayload);

      // Si el guardado es exitoso:
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_){
          Navigator.pop(context, true);
        });
      }

    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _save({required dynamic data}) async {

    try {
      final response = await _apiService.post(
          '/api/incidencia/write/',
          {
            'AC': 'save_incidencia',
            ...data
          }
      );

      if (response != null && response.isNotEmpty) {
        // Lógica de respuesta exitosa de la API
      } else {
        throw Exception('Respuesta de API vacía o inválida.');
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al registrar la incidencia: ${e.toString()}');
      rethrow; // FIX CRUCIAL: Relanzar la excepción para que _registerIncident la capture
    } finally {
      // No se usa setState aquí, lo hacemos en _registerIncident
    }
  }

  // Card que muestra la placa y el propietario
  Widget _buildHeaderCard() {
    final placa = widget.vehicleJsonData['placa'] ?? 'No Disponible';
    final nombre = widget.vehicleJsonData['nombreCompleto'] ?? 'No Disponible';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_car, color: Colors.black54),
                SizedBox(width: 8),
                Text('Información del Vehículo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow('Placa:', placa),
            _buildInfoRow('Propietario:', nombre),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Widget que muestra el estado de la geolocalización (AÑADIDO)
  Widget _buildLocationStatus() {
    IconData icon;
    Color color;
    String statusText;

    if (_isLocationLoading) {
      icon = Icons.gps_fixed_outlined;
      color = Colors.blue.shade600;
      statusText = 'Obteniendo ubicación...';
    } else if (_locationError != null) {
      icon = Icons.location_off_outlined;
      color = Colors.red.shade600;
      statusText = _locationError!;
    } else if (_currentPosition != null) {
      icon = Icons.location_on;
      color = Colors.green.shade600;
      statusText = 'Ubicación obtenida: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
    } else {
      icon = Icons.location_searching;
      color = Colors.grey;
      statusText = 'Ubicación pendiente.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ubicación del Incidente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color, size: 30),
          title: Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          trailing: _isLocationLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            onPressed: _getCurrentLocation,
          ),
        ),
      ],
    );
  }


  // Sección de Evidencia Fotográfica
  Widget _buildEvidenceSection() {
    final hasImages = _additionalImages.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Evidencia Fotográfica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${_additionalImages.length}/3', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 15),
        if (hasImages)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_additionalImages.length, (index) {
              final XFile file = _additionalImages[index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: kIsWeb
                        ? Image.network(file.path, fit: BoxFit.cover)
                        : Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: GestureDetector(
                      onTap: () => _removeEvidenceImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        const SizedBox(height: 10),
        if (_additionalImages.length < 3)
          _DashedBorderContainer(
            onTap: _addEvidenceImage,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.blue, size: 30),
                SizedBox(height: 5),
                Text('Añadir Evidencia', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final placa = widget.vehicleJsonData['placa'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Incidencia - $placa'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          onChanged: () {
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Información del Vehículo
              _buildHeaderCard(),
              const SizedBox(height: 10),

              // ESTATUS DE UBICACIÓN (AÑADIDO)
              _buildLocationStatus(),
              const SizedBox(height: 30),

              // Descripción Detallada
              const Text('Descripción Detallada del Incidente *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: maxDescriptionLength,
                decoration: InputDecoration(
                  hintText: 'Describe el incidente de manera detallada...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '${_descriptionController.text.length}/$maxDescriptionLength',
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // Evidencia Fotográfica
              _buildEvidenceSection(),
              const SizedBox(height: 40),

              // Botón de Registro Final
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving || !_isFormValid ? null : _registerIncident,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.add_circle_outline_rounded, size: 24),
                  label: Text(
                    _isSaving ? 'Registrando...' : 'Registrar Incidencia',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGET AUXILIAR PARA EL BORDE DISCONTINUO (Dashed Border)
class _DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _DashedBorderContainer({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.blue.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}