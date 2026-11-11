class UsuarioLogado {
  static int? idCliente;
  static String? nome;
  static String? email;

  static void definirUsuario({
    required int id,
    required String nomeUsuario,
    required String emailUsuario,
  }) {
    idCliente = id;
    nome = nomeUsuario;
    email = emailUsuario;
  }

  static void limparUsuario() {
    idCliente = null;
    nome = null;
    email = null;
  }
}