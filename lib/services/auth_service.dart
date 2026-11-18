import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import 'database_service.dart';

class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Autenticação local exclusiva para o Admin/Responsável gerenciar a receita.
/// O paciente NÃO precisa estar logado para ver e "tickar" os remédios.
class AuthService {
  static const _chaveSessao = 'usuario_id';
  static Usuario? usuarioAtual;

  static bool get estaLogado => usuarioAtual != null;
  static bool get ehAdminLogado => usuarioAtual?.ehAdmin ?? false;

  static String _hash(String senha) =>
      sha256.convert(utf8.encode(senha)).toString();

  static bool emailValido(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  static Future<void> restaurarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_chaveSessao);
    if (id != null) {
      usuarioAtual = await DatabaseService.instance.buscarUsuarioPorId(id);
    }
  }

  static Future<Usuario> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (nome.trim().isEmpty || email.trim().isEmpty || senha.isEmpty) {
      throw AuthException('Preencha todos os campos.');
    }
    if (!emailValido(email)) throw AuthException('E-mail inválido.');
    if (senha.length < 6) {
      throw AuthException('A senha deve ter pelo menos 6 caracteres.');
    }

    final db = DatabaseService.instance;
    if (await db.buscarUsuarioPorEmail(email.trim()) != null) {
      throw AuthException('Este e-mail já está cadastrado.');
    }

    // Todo responsável que cria conta é Admin para gerenciar receitas e constar na auditoria
    await db.inserirUsuario(Usuario(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      senhaHash: _hash(senha),
      papel: 'admin',
    ));
    return login(email: email, senha: senha);
  }

  static Future<Usuario> login({
    required String email,
    required String senha,
  }) async {
    if (email.trim().isEmpty || senha.isEmpty) {
      throw AuthException('Informe e-mail e senha.');
    }
    final u =
        await DatabaseService.instance.buscarUsuarioPorEmail(email.trim());
    if (u == null || u.senhaHash != _hash(senha)) {
      throw AuthException('E-mail ou senha inválidos.');
    }
    usuarioAtual = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveSessao, u.id!);
    return u;
  }

  static Future<void> logout() async {
    usuarioAtual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveSessao);
  }
}