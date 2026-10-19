import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// Panel del admin de un gimnasio (ej: recepción de Marfit).
/// Aquí se activa Premium escribiendo el correo del cliente.
/// El superadmin entra con [gimnasioId] para administrar cualquier gimnasio.
class PanelGimnasioScreen extends StatefulWidget {
  final int? gimnasioId;

  const PanelGimnasioScreen({super.key, this.gimnasioId});

  @override
  State<PanelGimnasioScreen> createState() => _PanelGimnasioScreenState();
}

class _PanelGimnasioScreenState extends State<PanelGimnasioScreen> {
  final _api = ApiService.instance;
  final _emailCtrl = TextEditingController();
  final _buscarCtrl = TextEditingController();
  PanelGimnasio? _panel;
  int _meses = 1;
  bool _cargando = true;
  bool _activando = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = _panel == null;
      _error = null;
    });
    try {
      final panel = await _api.panelGimnasio(gimnasioId: widget.gimnasioId);
      if (!mounted) return;
      setState(() {
        _panel = panel;
        if (!panel.mesesPermitidos.contains(_meses) &&
            panel.mesesPermitidos.isNotEmpty) {
          _meses = panel.mesesPermitidos.first;
        }
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

  Future<void> _activar() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!email.contains('@')) {
      mostrarMensaje(context, 'Escribe el correo con el que el cliente se registró');
      return;
    }

    setState(() => _activando = true);
    try {
      final mensaje = await _api.activarPremiumCliente(
        email: email,
        meses: _meses,
        gimnasioId: widget.gimnasioId,
      );
      if (!mounted) return;
      _emailCtrl.clear();
      FocusScope.of(context).unfocus();
      mostrarMensaje(context, mensaje);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _activando = false);
    }
  }

  Future<void> _quitar(MiembroGimnasio m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar Premium?'),
        content: Text(
          '${m.nombre} volverá al plan gratis. Úsalo si dejó de pagar la membresía.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colores.peligro),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final mensaje = await _api.quitarPremiumCliente(
        m.id,
        gimnasioId: widget.gimnasioId,
      );
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  void _renovar(MiembroGimnasio m) {
    _emailCtrl.text = m.email;
    mostrarMensaje(context, 'Elige los meses y toca "Activar Premium"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_panel == null ? 'Panel' : 'Panel ${_panel!.gimnasio.nombre}'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _panel == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final panel = _panel!;
    final filtro = _buscarCtrl.text.trim().toLowerCase();
    final miembros = panel.miembros
        .where(
          (m) =>
              filtro.isEmpty ||
              m.nombre.toLowerCase().contains(filtro) ||
              m.email.toLowerCase().contains(filtro),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ---- Activar Premium ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colores.premium),
                      SizedBox(width: 10),
                      Text(
                        'Activar Premium',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El cliente paga su membresía, tú escribes el correo con el que '
                    'se registró en la app y queda Premium.',
                    style: TextStyle(color: Colores.textoSuave),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo del cliente',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    onSubmitted: (_) => _activar(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Duración',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in panel.mesesPermitidos)
                        ButtonSegment(
                          value: m,
                          label: Text(m == 12 ? '1 año' : '$m mes${m == 1 ? '' : 'es'}'),
                        ),
                    ],
                    selected: {_meses},
                    onSelectionChanged: (s) => setState(() => _meses = s.first),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _activando ? null : _activar,
                    icon: const Icon(Icons.check_circle),
                    label: Text(_activando ? 'Activando...' : 'Activar Premium'),
                  ),
                ],
              ),
            ),
          ),

          // ---- Miembros ----
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Miembros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${panel.gimnasio.miembrosPremium} Premium activos',
                  style: const TextStyle(
                    color: Colores.premium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (panel.miembros.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _buscarCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o correo',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (panel.miembros.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay miembros.\nActiva el primero con su correo 👆',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          for (final m in miembros)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                leading: CircleAvatar(
                  backgroundColor: m.esPremium
                      ? Colores.premium.withValues(alpha: 0.18)
                      : Colores.superficieAlta,
                  child: Text(
                    m.nombre.isEmpty ? '?' : m.nombre[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: m.esPremium ? Colores.premium : Colores.textoSuave,
                    ),
                  ),
                ),
                title: Text(
                  m.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${m.email}\n'
                  '${m.esPremium ? 'Premium hasta el ${formatearFecha(m.premiumHasta!)}' : 'Sin Premium'}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (accion) {
                    if (accion == 'renovar') _renovar(m);
                    if (accion == 'quitar') _quitar(m);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'renovar',
                      child: Text(m.esPremium ? 'Renovar / extender' : 'Activar de nuevo'),
                    ),
                    if (m.esPremium)
                      const PopupMenuItem(
                        value: 'quitar',
                        child: Text('Quitar Premium'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
