import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _api = ApiService.instance;
  final _codigoCtrl = TextEditingController();
  Usuario? _usuario;
  Plan? _plan;
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
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final (usuario, plan) = await _api.perfil();
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _plan = plan;
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

  Future<void> _activarPremium() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      mostrarMensaje(context, 'Escribe tu código Premium');
      return;
    }

    setState(() => _activando = true);
    try {
      final mensaje = await _api.activarPremium(codigo);
      if (!mounted) return;
      _codigoCtrl.clear();
      mostrarMensaje(context, mensaje);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _activando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final tema = Theme.of(context);
    final usuario = _usuario!;
    final plan = _plan!;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Datos del usuario ----
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(usuario.nombre.isEmpty
                    ? '?'
                    : usuario.nombre[0].toUpperCase()),
              ),
              title: Text(usuario.nombre),
              subtitle: Text(usuario.email),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Plan ----
          if (usuario.esPremium)
            Card(
              color: tema.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, size: 36),
                title: const Text('Premium activo'),
                subtitle: Text(
                  usuario.premiumHasta == null
                      ? 'Rutinas y ejercicios ilimitados'
                      : 'Vence el ${formatearFecha(usuario.premiumHasta!)}',
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan gratis', style: tema.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Rutinas: ${plan.rutinasUsadas} de ${plan.limiteRutinas}'),
                    Text('Máximo ${plan.limiteEjerciciosPorRutina} ejercicios por rutina'),
                    const Divider(height: 32),
                    Text('Con Premium tienes:', style: tema.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const _Beneficio('Rutinas ilimitadas'),
                    const _Beneficio('Ejercicios ilimitados por rutina'),
                    const _Beneficio('Ejercicios exclusivos 🔒'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código Premium',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              onSubmitted: (_) => _activarPremium(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _activando ? null : _activarPremium,
              icon: const Icon(Icons.workspace_premium),
              label: Text(_activando ? 'Activando...' : 'Activar Premium'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  final String texto;

  const _Beneficio(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(texto),
        ],
      ),
    );
  }
}
