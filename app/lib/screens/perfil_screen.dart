import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import '../widgets/avatar.dart';
import '../widgets/nivel.dart';
import 'avatar_screen.dart';
import 'ayuda_screen.dart';
import 'bandeja_ayuda_screen.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';
import 'panel_gimnasio_screen.dart';
import 'superadmin_screen.dart';

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
  Progreso? _progreso;
  AvatarConfig? _avatar;
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
      _cargando = _usuario == null;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _api.perfil(),
        _api.progreso(),
        _api.avatar(),
      ]);
      final (usuario, plan) = resultados[0] as (Usuario, Plan);
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _plan = plan;
        _progreso = resultados[1] as Progreso;
        _avatar = (resultados[2] as DatosAvatar).avatar;
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

  /// Códigos de prueba (los de la tabla codigos_premium). Lo normal es que
  /// el Premium lo active el gimnasio, pero sirven para demos.
  Future<void> _activarCodigo() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      mostrarMensaje(context, 'Escribe tu código');
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

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    _cargar();
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
    if (_error != null && _usuario == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final usuario = _usuario!;
    final plan = _plan!;
    final progreso = _progreso;
    final esCliente = usuario.esCliente;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ---- Datos del usuario + nivel ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  if (_avatar != null && progreso != null && !progreso.bloqueado)
                    GestureDetector(
                      onTap: () => _abrir(const AvatarScreen()),
                      child: AvatarDibujo(
                        config: _avatar!,
                        tramo: tramoAvatar(progreso.nivel.nivel),
                        ancho: 64,
                      ),
                    )
                  else if (progreso != null && !progreso.bloqueado)
                    InsigniaNivel(nivel: progreso.nivel, tamano: 72)
                  else
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colores.superficieAlta,
                      child: Text(
                        usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colores.marca,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          usuario.email,
                          style: const TextStyle(color: Colores.textoSuave),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (usuario.esSuperadmin) const _Etiqueta('SUPERADMIN'),
                            if (usuario.esAdminGimnasio)
                              _Etiqueta('ADMIN ${usuario.gimnasioNombre?.toUpperCase() ?? ''}'),
                            if (usuario.esEntrenador)
                              _Etiqueta('ENTRENADOR ${usuario.gimnasioNombre?.toUpperCase() ?? ''}'),
                            if (usuario.esPremium)
                              const _Etiqueta('PREMIUM', color: Colores.premium),
                            if (progreso != null && !progreso.bloqueado)
                              _Etiqueta(progreso.nivel.titulo.toUpperCase()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Avatar y asistente ----
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural, color: Colores.marca),
                  title: const Text('Mi avatar'),
                  subtitle: Text(
                    _avatar == null
                        ? 'Créalo y míralo evolucionar al subir de nivel'
                        : 'Personaliza tu avatar y mira su evolución',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrir(const AvatarScreen()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined, color: Colores.marca),
                  title: const Text('Asistente de ejercicios'),
                  subtitle: const Text('Dudas de técnica, series, descanso y más'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrir(const ChatbotScreen()),
                ),
                if (esCliente) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: Colores.marca),
                    title: const Text('Pedir ayuda a un entrenador'),
                    subtitle: const Text('Que un entrenador de tu gimnasio se acerque'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(const AyudaScreen()),
                  ),
                ],
              ],
            ),
          ),
          if (usuario.esEntrenador)
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent, color: Colores.marca),
                title: const Text('Solicitudes de ayuda'),
                subtitle: Text('Socios de ${usuario.gimnasioNombre ?? 'tu gimnasio'} que piden un entrenador'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrir(const BandejaAyudaScreen()),
              ),
            ),

          // ---- Accesos de administración ----
          if (usuario.esSuperadmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colores.marca),
                title: const Text('Panel PonteChetado'),
                subtitle: const Text('Gimnasios y administradores'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrir(const SuperadminScreen()),
              ),
            ),
          if (usuario.esAdminGimnasio)
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront, color: Colores.marca),
                title: Text('Panel de ${usuario.gimnasioNombre ?? 'mi gimnasio'}'),
                subtitle: const Text('Premium de clientes, entrenadores y solicitudes de ayuda'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrir(const PanelGimnasioScreen()),
              ),
            ),

          // ---- Plan ----
          if (usuario.esPremium)
            Card(
              color: Colores.premium.withValues(alpha: 0.12),
              child: ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  size: 36,
                  color: Colores.premium,
                ),
                title: Text(
                  usuario.gimnasioNombre == null
                      ? 'Premium activo'
                      : 'Premium activo · ${usuario.gimnasioNombre}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  usuario.premiumHasta == null
                      ? 'Rutinas y ejercicios ilimitados'
                      : 'Vence el ${formatearFecha(usuario.premiumHasta!)}',
                ),
              ),
            )
          else if (esCliente)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan gratis',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text('Rutinas: ${plan.rutinasUsadas} de ${plan.limiteRutinas}'),
                    Text('Máximo ${plan.limiteEjerciciosPorRutina} ejercicios por rutina'),
                    const Divider(height: 28),
                    const Text(
                      'Con Premium tienes:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const _Beneficio('Rutinas ilimitadas'),
                    const _Beneficio('Ejercicios ilimitados por rutina'),
                    const _Beneficio('Ejercicios exclusivos'),
                    const _Beneficio('Niveles, XP y tu historial de entrenos'),
                    const SizedBox(height: 12),
                    const Text(
                      'Se activa en tu gimnasio: paga la membresía y dales tu correo '
                      '(mira la pestaña "Gimnasios").',
                      style: TextStyle(color: Colores.textoSuave),
                    ),
                  ],
                ),
              ),
            ),

          // ---- Código de prueba (demos) ----
          if (esCliente && !usuario.esPremium)
            Card(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('¿Tienes un código de prueba?'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    TextField(
                      controller: _codigoCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Código'),
                      onSubmitted: (_) => _activarCodigo(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _activando ? null : _activarCodigo,
                        child: Text(_activando ? 'Activando...' : 'Canjear'),
                      ),
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

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const _Etiqueta(this.texto, {this.color = Colores.marca});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
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
          const Icon(Icons.check_circle, size: 18, color: Colores.marca),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
