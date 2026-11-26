class Medicamento {
  final int? id;
  final String nome;
  final String dose;
  final List<String> horarios;
  final String observacao;
  final bool notificacaoFixa;
  final String medico;
  final String telefoneMedico;

  const Medicamento({
    this.id,
    required this.nome,
    required this.dose,
    required this.horarios,
    this.observacao = '',
    this.notificacaoFixa = true,
    this.medico = '',
    this.telefoneMedico = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'dose': dose,
        'horarios': horarios.join(','),
        'observacao': observacao,
        'notificacao_fixa': notificacaoFixa ? 1 : 0,
        'medico': medico,
        'telefone_medico': telefoneMedico,
      };

  factory Medicamento.fromMap(Map<String, dynamic> m) {
    final textoHorarios = (m['horarios'] as String? ?? '').trim();
    return Medicamento(
      id: m['id'] as int?,
      nome: m['nome'] as String,
      dose: m['dose'] as String,
      horarios: textoHorarios.isEmpty
          ? []
          : textoHorarios.split(',').map((e) => e.trim()).toList(),
      observacao: (m['observacao'] as String?) ?? '',
      notificacaoFixa: ((m['notificacao_fixa'] as int?) ?? 1) == 1,
      medico: (m['medico'] as String?) ?? '',
      telefoneMedico: (m['telefone_medico'] as String?) ?? '',
    );
  }
}