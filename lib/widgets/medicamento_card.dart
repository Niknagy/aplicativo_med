import 'package:flutter/material.dart';

import '../models/medicamento.dart';

/// Cartão usado na visão do Admin (lista com editar e excluir).
class MedicamentoCard extends StatelessWidget {
  final Medicamento medicamento;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const MedicamentoCard({
    super.key,
    required this.medicamento,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.medication)),
        title: Text(medicamento.nome,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${medicamento.dose}\nHorários: ${medicamento.horarios.join(', ')}'
          '${medicamento.observacao.isNotEmpty ? '\n${medicamento.observacao}' : ''}'
          '${medicamento.medico.isNotEmpty ? '\nTel. Médico: ${medicamento.medico}' : ''}'
          '${medicamento.medico.isNotEmpty ? '\nMédico: ${medicamento.medico}' : ''}'
          '${medicamento.telefoneMedico.isNotEmpty ? '\nTel. Médico: ${medicamento.telefoneMedico}' : ''}'
          '\n${medicamento.notificacaoFixa ? '🔒 Alerta Fixo (não sai até tickar)' : '🕶️ Modo Discreto / Date (pode dispensar)'}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit),
                onPressed: onEditar),
            IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: onExcluir),
          ],
        ),
      ),
    );
  }
}