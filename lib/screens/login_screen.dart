import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await AuthService.login(email: _email.text, senha: _senha.text);
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
      appBar: AppBar(title: const Text('Acesso do Responsável (Admin)')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 64, color: Colors.teal),
                  const SizedBox(height: 12),
                  Text('Área Restrita da Receita',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  const Text(
                    'Para apenas ver e marcar ("tickar") os remédios do dia não é preciso login. Entre aqui somente se você for o responsável por cadastrar ou alterar a receita.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'E-mail do Responsável',
                        border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o e-mail'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha', border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a senha' : null,
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
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Entrar como Admin'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/cadastro'),
                    child: const Text('Criar conta de Responsável (Admin)'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (_) => false),
                    child: const Text('Voltar para a tela de remédios (Paciente)'),
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