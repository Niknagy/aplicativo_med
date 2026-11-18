import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await AuthService.cadastrar(
          nome: _nome.text, email: _email.text, senha: _senha.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on AuthException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Responsável (Admin)')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nome,
                    decoration: const InputDecoration(
                        labelText: 'Nome do Responsável (para Auditoria)',
                        border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'E-mail', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      if (!AuthService.emailValido(v)) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha (mín. 6 caracteres)',
                        border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      if (v.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirma,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v != _senha.text ? 'As senhas não conferem' : null,
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _carregando ? null : _cadastrar,
                      child: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Cadastrar Admin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}