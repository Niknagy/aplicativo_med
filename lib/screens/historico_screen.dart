import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/medicamento.dart';
import '../models/registro_dose.dart';
import '../services/database_service.dart';

/// Histórico dos últimos 7 dias + Registro de Auditoria de alterações do Admin.
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _fmt = DateFormat('yyyy-MM-dd');
  late final List<DateTime> _dias;
  List<Medicamento> _meds = [];
  List<RegistroDose> _registros = [];
  List<LogAuditoria> _logsAuditoria = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _dias = List.generate(7, (i) => hoje.subtract(Duration(days: i)));
    _carregar();
  }

  Future<void> _carregar() async {
    final db = DatabaseService.instance;
    final meds = await db.listarMedicamentos();
    final regs = await db.historico(_fmt.format(_dias.last));
    final logs = await db.listarAuditoria();
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _registros = regs;
      _logsAuditoria = logs;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nomes = {for (final m in _meds) m.id: m.nome};
    final esperado = _meds.fold<int>(0, (s, m) => s + m.horarios.length);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico & Auditoria'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.fact_check), text: 'Doses (7 dias)'),
              Tab(icon: Icon(Icons.policy), text: 'Auditoria (Admin)'),
            ],
          ),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // ABA 1: Histórico de doses tomadas nos últimos 7 dias
                  ListView(
                    children: [
                      for (final dia in _dias) _linhaDia(dia, nomes, esperado),
                    ],
                  ),
                  // ABA 2: Registro de auditoria de quem alterou a receita
                  _abaAuditoria(),
                ],
              ),
      ),
    );
  }

  Widget _linhaDia(DateTime dia, Map<int?, String> nomes, int esperado) {
    final chave = _fmt.format(dia);
    final tomadas = _registros.where((r) => r.data == chave).toList();
    final completo = esperado > 0 && tomadas.length >= esperado;

    return ExpansionTile(
      leading: Icon(
        completo ? Icons.check_circle : Icons.warning_amber_rounded,
        color: completo ? Colors.green : Colors.orange,
      ),
      title: Text(DateFormat('EEE, dd/MM', 'pt_BR').format(dia)),
      subtitle: Text('${tomadas.length} de $esperado doses tomadas'),
      children: [
        if (tomadas.isEmpty)
          const ListTile(title: Text('Nenhuma dose marcada neste dia.')),
        for (final r in tomadas)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check, color: Colors.green),
            title: Text(nomes[r.medicamentoId] ?? 'Medicamento removido'),
            subtitle: Text(
                'Previsto ${r.horario} • marcado às ${r.horaMarcada ?? '--:--'}'),
          ),
      ],
    );
  }

  Widget _abaAuditoria() {
    if (_logsAuditoria.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma alteração de receita registrada até o momento.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logsAuditoria.length,
      itemBuilder: (_, i) {
        final log = _logsAuditoria[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.verified_user)),
            title: Text(
              '${log.acao} • ${log.dataHora}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${log.detalhes}\nResponsável: ${log.adminNome} (${log.adminEmail})',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}