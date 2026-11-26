import 'package:flutter/material.dart';

import '../models/medicamento.dart';

/// Linha grande com checkbox para o paciente marcar a dose do dia (sem login).
class DoseTile extends StatelessWidget {
  final Medicamento medicamento;
  final String horario;
  final bool tomado;
  final String? horaMarcada;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTestarAlarme;

  const DoseTile({
    super.key,
    required this.medicamento,
    required this.horario,
    required this.tomado,
    this.horaMarcada,
    required this.onChanged,
    this.onTestarAlarme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: tomado ? Colors.green.shade50 : null,
      child: CheckboxListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        value: tomado,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: !tomado && onTestarAlarme != null
            ? IconButton(
                tooltip: 'Testar notificação deste horário agora',
                icon: Icon(
                  medicamento.notificacaoFixa
                      ? Icons.notifications_active
                      : Icons.notifications_paused_outlined,
                  color: Colors.teal,
                ),
                onPressed: onTestarAlarme,
              )
            : null,
        title: Text(
          '$horario  •  ${medicamento.nome}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            decoration: tomado ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${medicamento.dose}'
          '${medicamento.observacao.isNotEmpty ? '\n${medicamento.observacao}' : ''}'
          '${medicamento.medico.isNotEmpty ? '\nMédico: ${medicamento.medico}' : ''}'
          '${medicamento.telefoneMedico.isNotEmpty ? '\nTel. Médico: ${medicamento.telefoneMedico}' : ''}'
          '\n${tomado ? '✅ Tomado às ${horaMarcada ?? horario}' : (medicamento.notificacaoFixa ? '🔒 Notificação fixa ativa' : '🕶️ Modo Discreto (Date)')}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}