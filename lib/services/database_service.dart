import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/medicamento.dart';
import '../models/registro_dose.dart';
import '../models/usuario.dart';

/// Camada de persistência (SQLite) + Auditoria + Despertador com Reaviso.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  final FlutterLocalNotificationsPlugin _notificacoes =
      FlutterLocalNotificationsPlugin();
  Timer? _timerReaviso;

  Future<Database> get _database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), 'ja_tomei_v2.db');
    return openDatabase(
      caminho,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            senha_hash TEXT NOT NULL,
            papel TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE medicamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            dose TEXT NOT NULL,
            horarios TEXT NOT NULL,
            observacao TEXT,
            notificacao_fixa INTEGER NOT NULL DEFAULT 1
          )''');
        await db.execute('''
          CREATE TABLE registros_dose (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL DEFAULT 0,
            medicamento_id INTEGER NOT NULL,
            data TEXT NOT NULL,
            horario TEXT NOT NULL,
            tomado INTEGER NOT NULL,
            hora_marcada TEXT,
            UNIQUE (medicamento_id, data, horario),
            FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
          )''');
        await db.execute('''
          CREATE TABLE auditoria_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            admin_nome TEXT NOT NULL,
            admin_email TEXT NOT NULL,
            acao TEXT NOT NULL,
            detalhes TEXT NOT NULL,
            data_hora TEXT NOT NULL
          )''');
      },
    );
  }

  // ---------- Despertador: 10 min antes + Notificação Fixa e Reaviso ----------
  Future<void> inicializarNotificacoes() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notificacoes.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _notificacoes
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _timerReaviso?.cancel();
    // Verifica a cada 1 minuto se falta 10 min ou se está na hora/atrasado
    _timerReaviso = Timer.periodic(
      const Duration(minutes: 1),
      (_) => verificarHorariosEReavisar(),
    );
  }

  int _idNotificacao(int medId, String horario) =>
      medId * 10000 + (int.tryParse(horario.replaceAll(':', '')) ?? 0);

  Future<void> verificarHorariosEReavisar() async {
    if (kIsWeb) return;
    final agora = DateTime.now();
    final hoje = DateFormat('yyyy-MM-dd').format(agora);
    final meds = await listarMedicamentos();
    final regs = await registrosDoDia(0, hoje);

    for (final m in meds) {
      if (m.id == null) continue;
      for (final h in m.horarios) {
        final chave = '${m.id}|$h';
        final jaTomou = regs[chave]?.tomado ?? false;

        if (jaTomou) {
          await cancelarNotificacaoDose(m.id!, h);
          continue;
        }

        final partes = h.split(':');
        if (partes.length != 2) continue;
        final alvo = DateTime(
          agora.year,
          agora.month,
          agora.day,
          int.tryParse(partes[0]) ?? 0,
          int.tryParse(partes[1]) ?? 0,
        );
        final diffMin = alvo.difference(agora).inMinutes;

        // 1) Avisa 10 minutos antes
        if (diffMin == 10) {
          await dispararNotificacao(
            medicamento: m,
            horario: h,
            aviso10MinAntes: true,
          );
        }

        // 2) Chegou a hora ou passou e não tickou: trava notificação e reavisa a cada 2 minutos
        if (diffMin <= 0 && diffMin >= -180) {
          final atraso = diffMin.abs();
          if (atraso % 2 == 0) {
            await dispararNotificacao(
              medicamento: m,
              horario: h,
              aviso10MinAntes: false,
              minutosAtraso: atraso,
            );
          }
        }
      }
    }
  }

  Future<void> dispararNotificacao({
    required Medicamento medicamento,
    required String horario,
    required bool aviso10MinAntes,
    int minutosAtraso = 0,
  }) async {
    if (kIsWeb || medicamento.id == null) return;

    // Se notificacaoFixa == true, a notificação do horário não pode ser removida arrastando
    final bool travarNaTela = !aviso10MinAntes && medicamento.notificacaoFixa;

    final String titulo;
    final String corpo;

    if (!medicamento.notificacaoFixa) {
      // Modo Discreto ("Date Mode") - esconde o nome do remédio e deixa limpar
      titulo = aviso10MinAntes
          ? 'Já tomei? • Lembrete em 10 min ($horario)'
          : 'Já tomei? • Compromisso das $horario';
      corpo = 'Abra o app para confirmar seu lembrete pessoal.';
    } else {
      titulo = aviso10MinAntes
          ? '⏳ Faltam 10 min ($horario): ${medicamento.nome}'
          : (minutosAtraso > 0
              ? '🚨 ATRASADO (${minutosAtraso}m): Tomar ${medicamento.nome}!'
              : '⏰ HORA DO REMÉDIO ($horario): ${medicamento.nome}');
      corpo = aviso10MinAntes
          ? 'Prepare sua dose de ${medicamento.dose}.'
          : 'Dose: ${medicamento.dose}. Entre no app "Já tomei?" e marque o check para liberar este alerta.';
    }

    final androidDetails = AndroidNotificationDetails(
      travarNaTela ? 'canal_fixo_ja_tomei' : 'canal_discreto_ja_tomei',
      travarNaTela ? 'Alertas Fixos de Medicamentos' : 'Alertas Discretos',
      channelDescription: 'Notificações do aplicativo Já tomei?',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: travarNaTela, // Impede o usuário de fechar a notificação sem entrar no app
      autoCancel: !travarNaTela,
    );

    await _notificacoes.show(
      _idNotificacao(medicamento.id!, horario),
      titulo,
      corpo,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  Future<void> cancelarNotificacaoDose(int medicamentoId, String horario) async {
    if (kIsWeb) return;
    await _notificacoes.cancel(_idNotificacao(medicamentoId, horario));
  }

  // ---------- Usuários (Admins) ----------
  Future<int> inserirUsuario(Usuario u) async {
    final db = await _database;
    return db.insert('usuarios', u.toMap()..remove('id'));
  }

  Future<Usuario?> buscarUsuarioPorEmail(String email) async {
    final db = await _database;
    final r = await db.query('usuarios',
        where: 'email = ?', whereArgs: [email.toLowerCase()], limit: 1);
    return r.isEmpty ? null : Usuario.fromMap(r.first);
  }

  Future<Usuario?> buscarUsuarioPorId(int id) async {
    final db = await _database;
    final r =
        await db.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Usuario.fromMap(r.first);
  }

  Future<int> contarUsuarios() async {
    final db = await _database;
    final r = await db.rawQuery('SELECT COUNT(*) AS total FROM usuarios');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ---------- CRUD de medicamentos + Auditoria Automática ----------
  Future<int> inserirMedicamento(Medicamento m, {Usuario? admin}) async {
    final db = await _database;
    final id = await db.insert('medicamentos', m.toMap()..remove('id'));
    if (admin != null) {
      await registrarAuditoria(
        admin: admin,
        acao: 'CADASTROU RECEITA',
        detalhes:
            'Adicionou "${m.nome}" (${m.dose}) nos horários [${m.horarios.join(', ')}] '
            '• Modo: ${m.notificacaoFixa ? "Notificação Fixa" : "Discreto (Date)"}',
      );
    }
    return id;
  }

  Future<List<Medicamento>> listarMedicamentos() async {
    final db = await _database;
    final r = await db.query('medicamentos', orderBy: 'nome COLLATE NOCASE');
    return r.map(Medicamento.fromMap).toList();
  }

  Future<int> atualizarMedicamento(
    Medicamento m, {
    Medicamento? anterior,
    Usuario? admin,
  }) async {
    final db = await _database;
    final rows = await db.update('medicamentos', m.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [m.id]);
    if (admin != null) {
      final antes = anterior != null
          ? 'De: "${anterior.nome}" (${anterior.dose}, [${anterior.horarios.join(', ')}], Fixa: ${anterior.notificacaoFixa}) -> '
          : '';
      await registrarAuditoria(
        admin: admin,
        acao: 'ALTEROU RECEITA',
        detalhes:
            '${antes}Para: "${m.nome}" (${m.dose}, [${m.horarios.join(', ')}], Fixa: ${m.notificacaoFixa})',
      );
    }
    return rows;
  }

  Future<int> excluirMedicamento(int id, {Medicamento? removido, Usuario? admin}) async {
    final db = await _database;
    if (removido != null) {
      for (final h in removido.horarios) {
        await cancelarNotificacaoDose(id, h);
      }
    }
    final rows = await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
    if (admin != null && removido != null) {
      await registrarAuditoria(
        admin: admin,
        acao: 'EXCLUIU RECEITA',
        detalhes:
            'Removeu "${removido.nome}" (${removido.dose}) que tinha os horários [${removido.horarios.join(', ')}]',
      );
    }
    return rows;
  }

  // ---------- Auditoria ----------
  Future<void> registrarAuditoria({
    required Usuario admin,
    required String acao,
    required String detalhes,
  }) async {
    final db = await _database;
    final agora = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final log = LogAuditoria(
      adminNome: admin.nome,
      adminEmail: admin.email,
      acao: acao,
      detalhes: detalhes,
      dataHora: agora,
    );
    await db.insert('auditoria_logs', log.toMap()..remove('id'));
  }

  Future<List<LogAuditoria>> listarAuditoria() async {
    final db = await _database;
    final r = await db.query('auditoria_logs', orderBy: 'id DESC');
    return r.map(LogAuditoria.fromMap).toList();
  }

// ---------- Registros de dose ----------
  Future<Map<String, RegistroDose>> _buscarMapaCru(String data) async {
    final db = await _database;
    final r = await db.query('registros_dose', where: 'data = ?', whereArgs: [data]);
    final mapa = <String, RegistroDose>{};
    for (final item in r) {
      final reg = RegistroDose.fromMap(item);
      mapa['${reg.medicamentoId}|${reg.horario}'] = reg;
    }
    return mapa;
  }

  Future<Map<String, RegistroDose>> registrosDoDia(
    int usuarioId,
    String data,
  ) async {
    return _buscarMapaCru(data);
  }

  Future<void> marcarDose({
    int usuarioId = 0,
    required int medicamentoId,
    required String data,
    required String horario,
    required bool tomado,
  }) async {
    final db = await _database;
    final registro = RegistroDose(
      usuarioId: usuarioId,
      medicamentoId: medicamentoId,
      data: data,
      horario: horario,
      tomado: tomado,
      horaMarcada: tomado ? DateFormat('HH:mm').format(DateTime.now()) : null,
    );
    await db.insert('registros_dose', registro.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (tomado) {
      await cancelarNotificacaoDose(medicamentoId, horario);
    }
  }

  Future<List<RegistroDose>> historico(String desde) async {
    final db = await _database;
    final r = await db.query('registros_dose',
        where: 'data >= ? AND tomado = 1',
        whereArgs: [desde],
        orderBy: 'data DESC, horario ASC');
    return r.map(RegistroDose.fromMap).toList();
  }
}