# Já tomei? — Controle de Medicamentos com Auditoria

Aplicativo multiplataforma desenvolvido em **Flutter** e **Dart** com persistência relacional em **SQLite** (Projeto Final P2).
O sistema auxilia no controle diário de medicamentos — especialmente voltado para pessoas com **TDAH** ou **Alzheimer** que frequentemente esquecem o horário da medicação ou têm dúvidas se já tomaram a dose do dia.

---

## ✨ Funcionalidades Principais

* **Modo Paciente sem Barreira de Login:** O paciente abre o aplicativo direto na tela principal (`HomeScreen`), visualiza a saudação dinâmica por período (*"Bom dia / Boa tarde / Boa noite: aqui estão seus remédios"*) e marca ("ticka") as doses tomadas com apenas um toque.
  
* **Área Restrita do Responsável / Admin (Autenticação & Proteção de Rotas):** Cadastro, login (com hash criptográfico `SHA-256`) e logout exclusivos para a pessoa de confiança responsável por gerenciar a receita médica no aparelho.
  
* **CRUD Completo de Medicamentos (Protegido):** Somente o administrador autenticado pode cadastrar novos medicamentos, definir a dosagem (`mg`), adicionar múltiplos horários (ex.: `08:00`, `12:00`, `16:00`, `22:00`), editar ou excluir registros.
    
  * No horário da dose (e a cada 2 minutos de atraso), mantém uma notificação fixa (`ongoing: true`) na barra do celular e um banner de alerta no topo do app que só desaparecem quando o usuário entra no aplicativo e marca o check de que tomou o remédio.
    
* **Modo Discreto ("Date Mode"):** Chave configurável pelo Admin em cada medicamento que permite desativar a trava da notificação fixa e ocultar o nome do remédio na tela de bloqueio, evitando constrangimentos em compromissos sociais ou encontros.
  
* **Trilha de Auditoria Local (`auditoria_logs`) e Histórico de 7 Dias:** Toda inclusão, edição ou exclusão feita na receita registra automaticamente no banco de dados o nome e e-mail do Admin responsável, a data/hora exata e os valores alterados (antes e depois).

---

## 🛠️ Tecnologias Utilizadas

* **Flutter & Dart** (Material Design 3, localização `pt_BR`, gerenciamento de rotas nomeadas com `onGenerateRoute`)
* **SQLite (`sqflite` + `path`)** (Persistência local relacional com `FOREIGN KEY` e `UNIQUE` constraints)
* **Segurança & Sessão (`crypto` + `shared_preferences`)** (Hash `SHA-256` de senhas e manutenção de sessão do Admin)
* **Notificações Locais (`flutter_local_notifications`)** (Notificações persistentes e motor de verificação periódica)
* **Internacionalização (`intl`)** (Formatação de datas, horários e histórico semanal)

---

## 📂 Estrutura do Projeto

```text
/lib
 ├── main.dart
 ├── /models
 │    ├── medicamento.dart
 │    ├── registro_dose.dart
 │    └── usuario.dart
 ├── /services
 │    ├── auth_service.dart
 │    └── database_service.dart
 ├── /screens
 │    ├── home_screen.dart
 │    ├── login_screen.dart
 │    ├── register_screen.dart
 │    ├── medicamento_form_screen.dart
 │    └── historico_screen.dart
 └── /widgets
      ├── dose_tile.dart
      └── medicamento_card.dart
