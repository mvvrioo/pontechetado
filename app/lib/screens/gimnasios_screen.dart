import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'panel_gimnasio_screen.dart';
import 'superadmin_screen.dart';

/// Gimnasios asociados + tu membresía. Los admins ven aquí el acceso a su panel.
class GimnasiosScreen extends StatefulWidget {
  const GimnasiosScreen({super.key});

  @override
  State<GimnasiosScreen> createState() => _GimnasiosScreenState();
}

class _GimnasiosScreenState extends State<GimnasiosScreen> {
  final _api = ApiService.instance;
  Usuario? _usuario;
  List<Gimnasio> _gimnasios = [];
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _api.perfil(),
        _api.listarGimnasios(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = (resultados[0] as (Usuario, Plan)).$1;
        _gimnasios = resultados[1] as List<Gimnasio>;
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

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gimnasios')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final u = _usuario!;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (u.esSuperadmin)
            _TarjetaAcceso(
              icono: Icons.admin_panel_settings,
              titulo: 'Panel PonteChetado',
              subtitulo: 'Crear gimnasios y asignar sus administradores',
              alTocar: () => _abrir(const SuperadminScreen()),
            ),
          if (u.esAdminGimnasio)
            _TarjetaAcceso(
              icono: Icons.storefront,
              titulo: 'Panel de ${u.gimnasioNombre ?? 'mi gimnasio'}',
              subtitulo: 'Activa Premium a tus clientes con su correo',
              alTocar: () => _abrir(const PanelGimnasioScreen()),
            ),
          if (!u.esAdminGimnasio && !u.esSuperadmin) _TarjetaMembresia(usuario: u),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Text(
              'Gimnasios asociados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          if (_gimnasios.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aún no hay gimnasios registrados.'),
              ),
            ),
          for (final g in _gimnasios) _TarjetaGimnasio(gimnasio: g),
        ],
      ),
    );
  }
}

class _TarjetaAcceso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;

  const _TarjetaAcceso({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colores.marca,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icono, color: Colors.black, size: 32),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black),
        onTap: alTocar,
      ),
    );
  }
}

/// Estado de la membresía del cliente y cómo activar Premium.
class _TarjetaMembresia extends StatelessWidget {
  final Usuario usuario;

  const _TarjetaMembresia({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final tieneGimnasio = usuario.gimnasioNombre != null;

    final String titulo;
    final String detalle;
    if (usuario.esPremium && tieneGimnasio) {
      titulo = 'Premium activo en ${usuario.gimnasioNombre}';
      detalle = usuario.premiumHasta == null
          ? 'Disfruta todas las funciones'
          : 'Vence el ${formatearFecha(usuario.premiumHasta!)}. Para renovar, paga tu membresía en recepción.';
    } else if (tieneGimnasio) {
      titulo = 'Tu Premium en ${usuario.gimnasioNombre} venció';
      detalle = 'Renueva tu membresía en el gimnasio y pide que la activen con tu correo:';
    } else {
      titulo = 'Activa Premium con tu gimnasio';
      detalle = 'Paga la membresía en uno de los gimnasios de abajo y en recepción dales este correo:';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: usuario.esPremium ? Colores.premium : Colores.textoSuave,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(detalle, style: const TextStyle(color: Colores.textoSuave)),
            if (!usuario.esPremium) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 14),
                decoration: BoxDecoration(
                  color: Colores.superficieAlta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        usuario.email,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar correo',
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: usuario.email));
                        mostrarMensaje(context, 'Correo copiado');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaGimnasio extends StatelessWidget {
  final Gimnasio gimnasio;

  const _TarjetaGimnasio({required this.gimnasio});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: gimnasio.esMiGimnasio
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Colores.marca, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colores.superficieAlta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                gimnasio.nombre.isEmpty ? '?' : gimnasio.nombre[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colores.marca,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          gimnasio.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (gimnasio.esMiGimnasio) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colores.marca,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TU GIMNASIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gimnasio.direccion ?? 'Gimnasio asociado a PonteChetado',
                    style: const TextStyle(color: Colores.textoSuave),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${gimnasio.miembrosPremium} miembro${gimnasio.miembrosPremium == 1 ? '' : 's'} Premium',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colores.premium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
