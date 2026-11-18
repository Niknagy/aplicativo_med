# 💊 Meus Remédios

Aplicativo Flutter para controle diário do uso de medicamentos. 
Um responsável (**admin**) cadastra a lista de remédios e horários, e o **usuário** marca, na hora de tomar, se a dose foi tomada. Pensado para ajudar pessoas que esquecem facilmente de tomar seus medicamentos.

Projeto Final (P2) — FATEC, Desenvolvimento de Software Multiplataforma.

## Funcionalidades principais

- **Cadastro, login e logout** de usuários, com sessão mantida ao fechar o app.
- **Dois perfis de acesso:**
  - **Admin** (primeiro usuário cadastrado): CRUD completo de medicamentos (nome, dose, horários e observação).
  - **Usuário**: vê as doses do dia e marca cada uma como tomada (checkbox), com barra de progresso diária.
- **Histórico dos últimos 7 dias** com a quantidade de doses tomadas por dia e o horário em que cada uma foi marcada.
- **Proteção de telas:** telas internas só abrem com usuário autenticado; o formulário de medicamentos só abre para admin.
- **Validação de formulários** e tratamento de erros (campos vazios, e-mail inválido, senha curta, e-mail já cadastrado, login inválido).

## Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| Flutter / Dart | Aplicativo multiplataforma |
| sqflite | Banco de dados SQLite local |
| crypto | Hash SHA-256 das senhas |
| shared_preferences | Guardar a sessão do usuário logado |
| intl | Formatação de datas (pt-BR) |

## Estrutura do projeto

```
lib/
├── main.dart                      # Rotas e proteção de telas
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart           # Admin (CRUD) ou Usuário (doses do dia)
│   ├── medicamento_form_screen.dart
│   └── historico_screen.dart
├── services/
│   ├── auth_service.dart          # Cadastro, login, logout, sessão
│   └── database_service.dart      # SQLite (tabelas e consultas)
├── models/
│   ├── usuario.dart
│   ├── medicamento.dart
│   └── registro_dose.dart
└── widgets/
    ├── medicamento_card.dart
    └── dose_tile.dart
```

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.

```bash
git clone <URL-DO-REPOSITORIO>
cd medicamentos_app
flutter pub get
flutter run
```

> O app usa SQLite (`sqflite`), portanto deve ser executado em **Android, iOS ou desktop** (não em Flutter Web).

### Primeiro acesso

1. Abra o app e toque em **"Não tem conta? Cadastre-se"**.
2. O **primeiro usuário cadastrado vira administrador** — cadastre os medicamentos com ele.
3. Saia e cadastre um segundo usuário (perfil **usuário**) para marcar as doses.

## Autenticação

Autenticação local própria, sem serviços externos:

- Cadastro e login por **e-mail e senha** (mínimo 6 caracteres).
- A senha **nunca é salva em texto puro**: é gravada como hash SHA-256.
- Após o login, o `id` do usuário é guardado em `shared_preferences` para manter a sessão.
- O campo `papel` (`admin` ou `usuario`) define o que cada perfil pode fazer.
- As rotas protegidas são verificadas em `main.dart` (`onGenerateRoute`).

## Base de dados

SQLite local, criado automaticamente na primeira execução (`medicamentos.db`):

| Tabela | Campos principais |
|---|---|
| `usuarios` | id, nome, email (único), senha_hash, papel |
| `medicamentos` | id, nome, dose, horarios (ex.: `08:00,20:00`), observacao |
| `registros_dose` | id, usuario_id, medicamento_id, data, horario, tomado, hora_marcada |

O **CRUD** de `medicamentos` é feito pelo admin; os `registros_dose` são criados/atualizados pelo usuário ao marcar cada dose. Ao excluir um medicamento, seus registros são removidos em cascata.

## Possíveis melhorias

- Sincronização na nuvem (Firebase/Supabase) para o responsável acompanhar à distância.
