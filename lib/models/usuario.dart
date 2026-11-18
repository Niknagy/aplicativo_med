class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String senhaHash;
  final String papel;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    this.papel = 'admin',
  });

  bool get ehAdmin => papel == 'admin';

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'senha_hash': senhaHash,
        'papel': papel,
      };

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'] as int?,
        nome: m['nome'] as String,
        email: m['email'] as String,
        senhaHash: m['senha_hash'] as String,
        papel: (m['papel'] as String?) ?? 'admin',
      );
}