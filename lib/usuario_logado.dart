class UsuarioLogado {
  static int? idCliente;
  static String? nome;
  static String? email;
  static String? token;

  static void definirUsuario({
    required int id,
    required String nomeUsuario,
    required String emailUsuario,
    required String tokenUsuario,
  }) {
    idCliente = id;
    nome = nomeUsuario;
    email = emailUsuario;
    token = tokenUsuario;
  }

  static void limparUsuario() {
    idCliente = null;
    nome = null;
    email = null;
    token = null;
  }
}