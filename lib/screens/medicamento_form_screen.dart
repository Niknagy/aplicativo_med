import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Formulário de criar/editar medicamento (somente Admin).
class MedicamentoFormScreen extends StatefulWidget {
  final Medicamento? medicamento;
  const MedicamentoFormScreen({super.key, this.medicamento});

  @override
  State<MedicamentoFormScreen> createState() => _MedicamentoFormScreenState();
}

class _MedicamentoFormScreenState extends State<MedicamentoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _dose;
  late final TextEditingController _obs;
  late final TextEditingController _medico;
  late final TextEditingController _telefoneMedico;
  late List<String> _horarios;
  late bool _notificacaoFixa;
  bool _erroHorario = false;
  bool _salvando = false;

  bool get _editando => widget.medicamento != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicamento;
    _nome = TextEditingController(text: m?.nome ?? '');
    _dose = TextEditingController(text: m?.dose ?? '');
    _obs = TextEditingController(text: m?.observacao ?? '');
    _medico = TextEditingController(text: m?.medico ?? '');
    _telefoneMedico = TextEditingController(text: m?.telefoneMedico ?? '');
    _horarios = [...?m?.horarios];
    _notificacaoFixa = m?.notificacaoFixa ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _dose.dispose();
    _obs.dispose();
    _medico.dispose();
    _telefoneMedico.dispose();
    super.dispose();
  }

  Future<void> _adicionarHorario() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    final texto =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    _incluirHorarioNaLista(texto);
  }

  void _incluirHorarioNaLista(String texto) {
    if (_horarios.contains(texto)) return;
    setState(() {
      _horarios = [..._horarios, texto]..sort();
      _erroHorario = false;
    });
  }

  Future<void> _salvar() async {
    final valido = _form.currentState!.validate();
    setState(() => _erroHorario = _horarios.isEmpty);
    if (!valido || _horarios.isEmpty) return;

    setState(() => _salvando = true);
    final m = Medicamento(
      id: widget.medicamento?.id,
      nome: _nome.text.trim(),
      dose: _dose.text.trim(),
      horarios: _horarios,
      observacao: _obs.text.trim(),
      notificacaoFixa: _notificacaoFixa,
      medico: _medico.text.trim(),
      telefoneMedico: _telefoneMedico.text.trim(),
    );
    final db = DatabaseService.instance;
    final admin = AuthService.usuarioAtual;

    if (_editando) {
      await db.atualizarMedicamento(
        m,
        anterior: widget.medicamento,
        admin: admin,
      );
    } else {
      await db.inserirMedicamento(m, admin: admin);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_editando ? 'Editar medicamento' : 'Novo medicamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(
                    labelText: 'Nome do medicamento',
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dose,
                decoration: const InputDecoration(
                    labelText: 'Dose / mg (ex.: 50mg - 1 comprimido)',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a dose' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obs,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medico,
                decoration: const InputDecoration(
                  labelText: 'Nome do médico',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneMedico,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone do médico',
                  hintText: '(11) 99999-9999',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text('Horários do Despertador',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final hPadrao in ['08:00', '12:00', '16:00', '22:00'])
                    if (!_horarios.contains(hPadrao))
                      ActionChip(
                        label: Text('+ $hPadrao'),
                        onPressed: () => _incluirHorarioNaLista(hPadrao),
                      ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final h in _horarios)
                    InputChip(
                      label: Text(h),
                      onDeleted: () => setState(() =>
                          _horarios = _horarios.where((x) => x != h).toList()),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm),
                    label: const Text('Escolher outro horário'),
                    onPressed: _adicionarHorario,
                  ),
                ],
              ),
              if (_erroHorario)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Adicione pelo menos um horário',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: Text(
                    _notificacaoFixa
                        ? 'Notificação Fixa Obrigatória'
                        : 'Modo Discreto (Date Mode)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _notificacaoFixa
                        ? 'Avisa 10 min antes e mantém a notificação travada no celular (com reaviso) até a pessoa entrar no app e tickar.'
                        : 'Desativa a trava e oculta o nome do remédio na notificação para evitar vergonha em encontros/público.',
                  ),
                  value: _notificacaoFixa,
                  onChanged: (v) => setState(() => _notificacaoFixa = v),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  child: const Text('Salvar na Receita (com Auditoria)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}