class RegistroDose {
  final int? id;
  final int usuarioId;
  final int medicamentoId;
  final String data;
  final String horario;
  final bool tomado;
  final String? horaMarcada;

  const RegistroDose({
    this.id,
    this.usuarioId = 0,
    required this.medicamentoId,
    required this.data,
    required this.horario,
    required this.tomado,
    this.horaMarcada,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'medicamento_id': medicamentoId,
        'data': data,
        'horario': horario,
        'tomado': tomado ? 1 : 0,
        'hora_marcada': horaMarcada,
      };

  factory RegistroDose.fromMap(Map<String, dynamic> m) => RegistroDose(
        id: m['id'] as int?,
        usuarioId: (m['usuario_id'] as int?) ?? 0,
        medicamentoId: m['medicamento_id'] as int,
        data: m['data'] as String,
        horario: m['horario'] as String,
        tomado: (m['tomado'] as int) == 1,
        horaMarcada: m['hora_marcada'] as String?,
      );
}

class LogAuditoria {
  final int? id;
  final String adminNome;
  final String adminEmail;
  final String acao;
  final String detalhes;
  final String dataHora;

  const LogAuditoria({
    this.id,
    required this.adminNome,
    required this.adminEmail,
    required this.acao,
    required this.detalhes,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'admin_nome': adminNome,
        'admin_email': adminEmail,
        'acao': acao,
        'detalhes': detalhes,
        'data_hora': dataHora,
      };

  factory LogAuditoria.fromMap(Map<String, dynamic> m) => LogAuditoria(
        id: m['id'] as int?,
        adminNome: m['admin_nome'] as String,
        adminEmail: m['admin_email'] as String,
        acao: m['acao'] as String,
        detalhes: m['detalhes'] as String,
        dataHora: m['data_hora'] as String,
      );
}