import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import '../widgets/avatar.dart';

/// Editor del avatar: género, piel, peinado y colores.
/// Abajo muestra cómo evoluciona según el nivel.
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  final _api = ApiService.instance;
  DatosAvatar? _datos;
  AvatarConfig _config = const AvatarConfig();
  int? _tramoVista; // tramo que se está previsualizando (null = el real)
  bool _cargando = true;
  bool _guardando = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _api.avatar();
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _config = datos.avatar ?? const AvatarConfig();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  int get _tramoReal => tramoAvatar(_datos?.nivel.nivel ?? 1);

  Future<void> _guardar() async {
    if (!(_datos?.esPremium ?? false)) {
      mostrarDialogoPremium(context, 'El avatar es una función Premium.');
      return;
    }
    setState(() => _guardando = true);
    try {
      final mensaje = await _api.guardarAvatar(_config);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _cambiar(AvatarConfig nuevo) => setState(() => _config = nuevo);

  @override
  Widget build(BuildContext context) {
    final premium = _datos?.esPremium ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi avatar')),
      body: _construirCuerpo(),
      bottomNavigationBar: _datos == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: Icon(premium ? Icons.check : Icons.lock),
                  label: Text(
                    !premium
                        ? 'Función Premium'
                        : _guardando
                            ? 'Guardando...'
                            : 'Guardar avatar',
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final datos = _datos!;
    final tramo = _tramoVista ?? _tramoReal;
    final viendoOtro = _tramoVista != null && _tramoVista != _tramoReal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (!datos.esPremium)
          Card(
            color: Colores.premium.withValues(alpha: 0.12),
            child: const ListTile(
              leading: Icon(Icons.workspace_premium, color: Colores.premium),
              title: Text('Función Premium', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Puedes probar cómo se ve, pero para guardarlo necesitas Premium.'),
            ),
          ),

        // ---- Vista previa ----
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const RadialGradient(
              colors: [Colores.marcaProfunda, Colores.superficie],
              radius: 0.9,
            ),
            border: Border.all(color: Colores.borde),
          ),
          child: Column(
            children: [
              AvatarDibujo(config: _config, tramo: tramo, ancho: 170),
              const SizedBox(height: 12),
              Text(
                viendoOtro
                    ? 'Así te verás como ${nombresTramo[tramo]} (nivel ${nivelesTramo[tramo]}+)'
                    : 'Nivel ${datos.nivel.nivel} · ${datos.nivel.titulo}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (viendoOtro)
                TextButton(
                  onPressed: () => setState(() => _tramoVista = null),
                  child: const Text('Volver a mi nivel'),
                ),
            ],
          ),
        ),

        // ---- Opciones ----
        const _Titulo('Género'),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'masculino', label: Text('Masculino'), icon: Icon(Icons.male)),
            ButtonSegment(value: 'femenino', label: Text('Femenino'), icon: Icon(Icons.female)),
          ],
          selected: {_config.genero},
          onSelectionChanged: (s) => _cambiar(_config.copyWith(genero: s.first)),
        ),
        const _Titulo('Tono de piel'),
        _SelectorColor(
          colores: pielesAvatar,
          elegido: _config.piel,
          alElegir: (i) => _cambiar(_config.copyWith(piel: i)),
        ),
        const _Titulo('Peinado'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < peinadosAvatar.length; i++)
              ChoiceChip(
                label: Text(peinadosAvatar[i]),
                selected: _config.peinado == i,
                onSelected: (_) => _cambiar(_config.copyWith(peinado: i)),
              ),
          ],
        ),
        const _Titulo('Color de pelo'),
        _SelectorColor(
          colores: pelosAvatar,
          elegido: _config.colorPelo,
          alElegir: (i) => _cambiar(_config.copyWith(colorPelo: i)),
        ),
        const _Titulo('Color de polera'),
        _SelectorColor(
          colores: ropasAvatar,
          elegido: _config.colorRopa,
          alElegir: (i) => _cambiar(_config.copyWith(colorRopa: i)),
        ),

        // ---- Evolución por nivel ----
        const _Titulo('Evolución al subir de nivel'),
        const Text(
          'Toca una etapa para ver cómo se verá tu avatar.',
          style: TextStyle(color: Colores.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nombresTramo.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _EtapaEvolucion(
              config: _config,
              tramo: i,
              desbloqueada: i <= _tramoReal,
              seleccionada: i == tramo,
              alTocar: () => setState(() => _tramoVista = i),
            ),
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}

class _SelectorColor extends StatelessWidget {
  final List<Color> colores;
  final int elegido;
  final ValueChanged<int> alElegir;

  const _SelectorColor({required this.colores, required this.elegido, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < colores.length; i++)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => alElegir(i),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colores[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == elegido ? Colores.marca : Colores.borde,
                  width: i == elegido ? 3 : 1.5,
                ),
              ),
              child: i == elegido
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: colores[i].computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _EtapaEvolucion extends StatelessWidget {
  final AvatarConfig config;
  final int tramo;
  final bool desbloqueada;
  final bool seleccionada;
  final VoidCallback alTocar;

  const _EtapaEvolucion({
    required this.config,
    required this.tramo,
    required this.desbloqueada,
    required this.seleccionada,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: alTocar,
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? Colores.marca : Colores.borde,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: desbloqueada ? 1 : 0.55,
                  child: AvatarDibujo(config: config, tramo: tramo, ancho: 56),
                ),
                // Candado chico en la esquina, para que se vea el avatar
                if (!desbloqueada)
                  const Positioned(
                    top: -2,
                    right: -14,
                    child: Icon(Icons.lock, color: Colores.premium, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              nombresTramo[tramo],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              'Nivel ${nivelesTramo[tramo]}+',
              style: const TextStyle(fontSize: 11, color: Colores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
