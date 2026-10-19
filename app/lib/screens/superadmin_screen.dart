import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'panel_gimnasio_screen.dart';

/// Panel del equipo PonteChetado: gimnasios asociados y sus administradores.
class SuperadminScreen extends StatefulWidget {
  const SuperadminScreen({super.key});

  @override
  State<SuperadminScreen> createState() => _SuperadminScreenState();
}

class _SuperadminScreenState extends State<SuperadminScreen> {
  final _api = ApiService.instance;
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
      _cargando = _gimnasios.isEmpty;
      _error = null;
    });
    try {
      final gimnasios = await _api.listarGimnasios();
      if (!mounted) return;
      setState(() {
        _gimnasios = gimnasios;
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

  Future<void> _crearGimnasio() async {
    final datos = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _DialogoNuevoGimnasio(),
    );
    if (datos == null) return;

    try {
      final mensaje = await _api.crearGimnasio(datos.$1, datos.$2);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _asignarAdmin(Gimnasio g) async {
    final datos = await showDialog<_DatosAdmin>(
      context: context,
      builder: (_) => _DialogoAsignarAdmin(gimnasio: g.nombre),
    );
    if (datos == null) return;

    try {
      final mensaje = await _api.asignarAdminGimnasio(
        gimnasioId: g.id,
        email: datos.email,
        nombre: datos.nombre,
        password: datos.password,
      );
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _quitarAdmin(AdminGimnasio a) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar admin?'),
        content: Text('${a.email} volverá a ser una cuenta normal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final mensaje = await _api.quitarAdminGimnasio(a.id);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel PonteChetado')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearGimnasio,
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo gimnasio'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _gimnasios.isEmpty) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          for (final g in _gimnasios)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront, color: Colores.marca),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${g.miembrosPremium} Premium',
                          style: const TextStyle(
                            color: Colores.premium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (g.direccion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 34),
                        child: Text(
                          g.direccion!,
                          style: const TextStyle(color: Colores.textoSuave),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Administradores',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colores.textoSuave,
                      ),
                    ),
                    if (g.admins.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Sin admin todavía'),
                      ),
                    for (final a in g.admins)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(a.nombre),
                        subtitle: Text(a.email),
                        trailing: IconButton(
                          tooltip: 'Quitar admin',
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _quitarAdmin(a),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _asignarAdmin(g),
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Asignar admin'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PanelGimnasioScreen(gimnasioId: g.id),
                                ),
                              );
                              _cargar();
                            },
                            icon: const Icon(Icons.groups),
                            label: const Text('Ver panel'),
                          ),
                        ),
                      ],
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

class _DialogoNuevoGimnasio extends StatefulWidget {
  const _DialogoNuevoGimnasio();

  @override
  State<_DialogoNuevoGimnasio> createState() => _DialogoNuevoGimnasioState();
}

class _DialogoNuevoGimnasioState extends State<_DialogoNuevoGimnasio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo gimnasio'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dirCtrl,
              decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (_nombreCtrl.text.trim(), _dirCtrl.text.trim()));
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _DatosAdmin {
  final String email;
  final String nombre;
  final String password;

  _DatosAdmin(this.email, this.nombre, this.password);
}

class _DialogoAsignarAdmin extends StatefulWidget {
  final String gimnasio;

  const _DialogoAsignarAdmin({required this.gimnasio});

  @override
  State<_DialogoAsignarAdmin> createState() => _DialogoAsignarAdminState();
}

class _DialogoAsignarAdminState extends State<_DialogoAsignarAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Admin de ${widget.gimnasio}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  hintText: 'pedrito@marfit.cl',
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Escribe un correo válido'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Si la cuenta todavía no existe, completa esto para crearla:',
                style: TextStyle(fontSize: 13, color: Colores.textoSuave),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial (opcional)',
                  helperText: 'Mínimo 8 caracteres',
                ),
                validator: (v) => (v != null && v.isNotEmpty && v.length < 8)
                    ? 'Mínimo 8 caracteres'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _DatosAdmin(
                _emailCtrl.text.trim().toLowerCase(),
                _nombreCtrl.text.trim(),
                _passCtrl.text,
              ),
            );
          },
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
