import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../detalle/prenda_detalle_screen.dart';
import 'models/recomendacion_ia_model.dart';
import 'services/ia_service.dart';

/// Pantalla del Asistente de Moda IA (CU22).
///
/// Permite al usuario indicar sus preferencias de estilo y recibir
/// recomendaciones de prendas generadas por el modulo de IA del backend.
class AsistenteModa extends StatefulWidget {
  const AsistenteModa({super.key});

  @override
  State<AsistenteModa> createState() => _AsistenteModaState();
}

class _AsistenteModaState extends State<AsistenteModa> {
  final IAService _servicio = IAService();
  final _temporadaCtrl = TextEditingController();

  // Opciones de los dropdowns
  static const _estilos = ['Casual', 'Formal', 'Deportivo', 'Elegante'];
  static const _ocasiones = [
    'Trabajo',
    'Evento social',
    'Deporte',
    'Salida informal',
    'Noche especial',
  ];
  static const _generos = ['Masculino', 'Femenino', 'Unisex'];
  static const _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  // Valores seleccionados
  String _estilo = _estilos.first;
  String _ocasion = _ocasiones.first;
  String _genero = _generos.first;
  String _talla = _tallas[2]; // M por defecto

  // Estado de la respuesta
  bool _cargando = false;
  RespuestaRecomendacionIA? _respuesta;

  @override
  void dispose() {
    _temporadaCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Logica de negocio
  // -------------------------------------------------------------------------

  Future<void> _obtenerRecomendaciones() async {
    setState(() {
      _cargando = true;
      _respuesta = null;
    });

    final peticion = RecomendacionIAPeticion(
      estilo: _estilo,
      ocasion: _ocasion,
      genero: _genero,
      talla: _talla,
      temporada: _temporadaCtrl.text.trim().isEmpty
          ? null
          : _temporadaCtrl.text.trim(),
      limite: 6,
    );

    try {
      final respuesta = await _servicio.recomendar(peticion);
      if (!mounted) return;
      setState(() => _respuesta = respuesta);
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarError(e.message);
    } catch (_) {
      if (!mounted) return;
      _mostrarError('No se pudo contactar con el servidor de IA.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: fsDanger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _irADetalle(int idPrenda) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrendaDetalleScreen(idPrenda: idPrenda),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Moda IA'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(),
            const SizedBox(height: 20),
            _formulario(),
            const SizedBox(height: 20),
            _botonRecomendar(),
            const SizedBox(height: 24),
            if (_cargando) _indicadorCarga(),
            if (_respuesta != null) _seccionResultados(_respuesta!),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fsGoldWash,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE4D4BC)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: fsGoldDeep, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estilista IA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fsGoldDeep,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cuéntame tus preferencias y encontraré las prendas perfectas para ti.',
                  style: TextStyle(fontSize: 12, color: fsInkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: fsBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelSeccion('TUS PREFERENCIAS'),
            const SizedBox(height: 16),

            // Estilo
            _dropdownField<String>(
              label: 'Estilo',
              value: _estilo,
              items: _estilos,
              onChanged: (v) => setState(() => _estilo = v!),
            ),
            const SizedBox(height: 14),

            // Ocasion
            _dropdownField<String>(
              label: 'Ocasión',
              value: _ocasion,
              items: _ocasiones,
              onChanged: (v) => setState(() => _ocasion = v!),
            ),
            const SizedBox(height: 14),

            // Genero
            _dropdownField<String>(
              label: 'Género',
              value: _genero,
              items: _generos,
              onChanged: (v) => setState(() => _genero = v!),
            ),
            const SizedBox(height: 14),

            // Talla
            _dropdownField<String>(
              label: 'Talla',
              value: _talla,
              items: _tallas,
              onChanged: (v) => setState(() => _talla = v!),
            ),
            const SizedBox(height: 14),

            // Temporada / clima libre
            TextField(
              controller: _temporadaCtrl,
              decoration: const InputDecoration(
                labelText: 'Temporada o clima (opcional)',
                hintText: 'Ej: Verano, Día lluvioso, Frío andino…',
                prefixIcon: Icon(Icons.wb_sunny_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _labelSeccion(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: fsInkMuted,
      ),
    );
  }

  Widget _botonRecomendar() {
    return FilledButton.icon(
      onPressed: _cargando ? null : _obtenerRecomendaciones,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('OBTENER RECOMENDACIONES'),
    );
  }

  Widget _indicadorCarga() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'El estilista IA está preparando tu outfit…',
              style: TextStyle(color: fsInkMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionResultados(RespuestaRecomendacionIA resp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mensaje del estilista
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: fsSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: fsBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assistant, color: fsGoldDeep, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Tu Estilista IA',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: fsGoldDeep,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (resp.esFallback) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: const Color(0xFFFFEBA0)),
                      ),
                      child: const Text(
                        'SUGERENCIA GENERAL',
                        style: TextStyle(fontSize: 9, color: Color(0xFF856404)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                resp.mensajeEstilista,
                style: const TextStyle(
                    color: fsInkSoft, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _labelSeccion('PRENDAS RECOMENDADAS · ${resp.prendas.length} resultado(s)'),
        const SizedBox(height: 12),

        if (resp.prendas.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No se encontraron prendas disponibles para este perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: fsInkMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resp.prendas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _tarjetaPrenda(resp.prendas[i]),
          ),
      ],
    );
  }

  Widget _tarjetaPrenda(PrendaRecomendada prenda) {
    return GestureDetector(
      onTap: () => _irADetalle(prenda.idPrenda),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: fsBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            SizedBox(
              width: 110,
              height: 130,
              child: redImagen(prenda.imagenUrl),
            ),

            // Datos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria
                    if (prenda.categoria != null) ...[
                      Text(
                        prenda.categoria!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: fsInkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Nombre
                    Text(
                      prenda.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Precio + stock
                    Row(
                      children: [
                        Text(
                          'Bs ${prenda.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        badgeStock(prenda.stockTotal),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Justificacion IA
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fsGoldWash,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 12, color: fsGoldDeep),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              prenda.justificacion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: fsInkSoft,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Ver detalle →',
                        style: TextStyle(
                          fontSize: 11,
                          color: fsGoldDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
