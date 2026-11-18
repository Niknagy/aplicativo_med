import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/medicamento.dart';
import '../models/registro_dose.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/dose_tile.dart';
import '../widgets/medicamento_card.dart';

/// Tela principal do "Já tomei?".
/// Paciente (sem login): vê "Bom dia/tarde/noite: aqui estão seus remédios" e "ticka" as doses.
/// Admin (logado): gerencia a receita (CRUD) com registro de auditoria.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService.instance;
  List<Medicamento> _meds = [];
  Map<String, RegistroDose> _registros = {};
  bool _carregando = true;
  bool _modoEdicaoAdmin = false;
  Timer? _timerTela;

  String get _hoje => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _saudacaoPeriodo {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) {
      return 'Bom dia: aqui estão seus remédios ☀️';
    } else if (h >= 12 && h < 18) {
      return 'Boa tarde: aqui estão seus remédios 🌤️';
    } else {
      return 'Boa noite: aqui estão seus remédios 🌙';
    }
  }

  @override
  void initState() {
    super.initState();
    _modoEdicaoAdmin = AuthService.ehAdminLogado;
    _carregar();
    // Atualiza a tela a cada 30s para exibir avisos de 10 min antes ou doses atrasadas
    _timerTela = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timerTela?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final meds = await _db.listarMedicamentos();
    final regs = await _db.registrosDoDia(0, _hoje);
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _registros = regs;
      _carregando = false;
    });
  }

  Future<void> _abrirForm([Medicamento? m]) async {
    final salvo =
        await Navigator.of(context).pushNamed('/medicamento', arguments: m);
    if (salvo == true) _carregar();
  }

  Future<void> _excluir(Medicamento m) async {
    final admin = AuthService.usuarioAtual;
    if (admin == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir medicamento'),
        content: Text(
          'Deseja excluir "${m.nome}"?\n'
          'Esta exclusão ficará gravada na auditoria em nome de ${admin.nome}.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    await _db.excluirMedicamento(m.id!, removido: m, admin: admin);
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicamento excluído e registrado na auditoria.')),
    );
  }

  Future<void> _marcar(Medicamento m, String horario, bool tomado) async {
    await _db.marcarDose(
      medicamentoId: m.id!,
      data: _hoje,
      horario: horario,
      tomado: tomado,
    );
    await _carregar();
    if (!mounted) return;
    if (tomado) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${m.nome} ($horario) marcado como tomado! Notificação liberada.'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _entrarComoAdmin() async {
    await Navigator.of(context).pushNamed('/login');
    if (!mounted) return;
    setState(() {
      _modoEdicaoAdmin = AuthService.ehAdminLogado;
    });
    _carregar();
  }

  Future<void> _sairDoAdmin() async {
    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      _modoEdicaoAdmin = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo Admin encerrado. O paciente pode usar o app normalmente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = AuthService.usuarioAtual;
    final estaComoAdmin = AuthService.ehAdminLogado;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          estaComoAdmin && _modoEdicaoAdmin
              ? 'Receita • Admin (${admin!.nome})'
              : 'Já tomei?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (estaComoAdmin)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _modoEdicaoAdmin = !_modoEdicaoAdmin),
              icon: Icon(_modoEdicaoAdmin ? Icons.checklist : Icons.edit_note),
              label: Text(_modoEdicaoAdmin ? 'Ver Check' : 'Editar Receita'),
            ),
          IconButton(
            tooltip: 'Histórico & Auditoria',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed('/historico'),
          ),
          if (estaComoAdmin)
            IconButton(
              tooltip: 'Sair do Admin (Trancar Receita)',
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _sairDoAdmin,
            )
          else
            TextButton.icon(
              onPressed: _entrarComoAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Área Admin'),
            ),
        ],
      ),
      floatingActionButton: (estaComoAdmin && _modoEdicaoAdmin)
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo Remédio'),
            )
          : null,
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : (estaComoAdmin && _modoEdicaoAdmin)
              ? _corpoAdmin()
              : _corpoUsuario(),
    );
  }

  Widget _corpoAdmin() {
    if (_meds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum medicamento cadastrado na receita.\nToque em "Novo Remédio" para configurar os horários.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.security, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auditoria ativa: alterações feitas aqui ficam registradas em nome de ${AuthService.usuarioAtual?.nome}.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            children: [
              for (final m in _meds)
                MedicamentoCard(
                  medicamento: m,
                  onEditar: () => _abrirForm(m),
                  onExcluir: () => _excluir(m),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corpoUsuario() {
    // Doses do dia ordenadas por horário: ex. 08:00, 12:00, 16:00, 22:00
    final doses = <({Medicamento med, String horario})>[
      for (final m in _meds)
        for (final h in m.horarios) (med: m, horario: h),
    ]..sort((a, b) => a.horario.compareTo(b.horario));

    final agora = DateTime.now();
    // Verifica se há alguma dose a <= 10 minutos ou já atrasada e não tomada
    final pendentesUrgentes = doses.where((d) {
      final tomado = _registros['${d.med.id}|${d.horario}']?.tomado ?? false;
      if (tomado) return false;
      final partes = d.horario.split(':');
      if (partes.length != 2) return false;
      final alvo = DateTime(agora.year, agora.month, agora.day,
          int.tryParse(partes[0]) ?? 0, int.tryParse(partes[1]) ?? 0);
      final diffMin = alvo.difference(agora).inMinutes;
      return diffMin <= 10;
    }).toList();

    final tomadas = doses
        .where((d) => _registros['${d.med.id}|${d.horario}']?.tomado ?? false)
        .length;

    return Column(
      children: [
        // Cabeçalho: "Bom dia, tarde e noite: aqui estão seus remédios"
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _saudacaoPeriodo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                doses.isEmpty
                    ? 'Nenhum horário configurado ainda.'
                    : '$tomadas de ${doses.length} doses tomadas hoje',
              ),
              if (doses.isNotEmpty) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: tomadas / doses.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),

        // Banner fixo que não sai até a pessoa tickar o remédio pendente/próximo
        if (pendentesUrgentes.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade400, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm_on, color: Colors.red.shade900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Atenção: Você tem ${pendentesUrgentes.length} dose(s) no horário ou próxima(s) (aviso de 10 min). Marque a caixinha abaixo assim que tomar para desligar o alerta!',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: doses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum medicamento cadastrado ainda.\n'
                      'Peça ao responsável para tocar em "Área Admin" no topo e cadastrar a receita.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final d in doses)
                      DoseTile(
                        medicamento: d.med,
                        horario: d.horario,
                        tomado:
                            _registros['${d.med.id}|${d.horario}']?.tomado ??
                                false,
                        horaMarcada:
                            _registros['${d.med.id}|${d.horario}']?.horaMarcada,
                        onChanged: (v) => _marcar(d.med, d.horario, v),
                        onTestarAlarme: () async {
                          await _db.dispararNotificacao(
                            medicamento: d.med,
                            horario: d.horario,
                            aviso10MinAntes: false,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                d.med.notificacaoFixa
                                    ? '🔔 Notificação FIXA enviada para a barra do celular! Ela só sai quando você tickar "${d.med.nome}".'
                                    : '🕶️ Notificação discreta enviada (Modo Date).',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}