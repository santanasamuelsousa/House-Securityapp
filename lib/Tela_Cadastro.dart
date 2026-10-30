
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class TelaCadastroOpcaoC extends StatefulWidget {
  const TelaCadastroOpcaoC({super.key});

  @override
  State<TelaCadastroOpcaoC> createState() =>
      _TelaCadastroOpcaoCState();
}

class _TelaCadastroOpcaoCState extends State<TelaCadastroOpcaoC> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _telefoneController = TextEditingController();

  int _etapa = 1;
  bool _senhaOculta = true;
  bool _carregando = false;

  static const Color _principal = Color(0xFF0F172A);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _avancar() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _etapa = 2;
    });
  }

  void _voltar() {
    FocusScope.of(context).unfocus();

    setState(() {
      _etapa = 1;
    });
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
    });

    try {
      final resposta = await http
          .post(
            Uri.parse('http://localhost:8080/api/cadastro'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
              'cpf': _cpfController.text.replaceAll(RegExp(r'\D'), ''),
              'cep': _cepController.text.replaceAll(RegExp(r'\D'), ''),
              'rua': _ruaController.text.trim(),
              'numero': _numeroController.text.trim(),
              'telefone':
                  _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      String mensagem;

      try {
        final dados = jsonDecode(resposta.body);
        mensagem = dados['mensagem']?.toString() ??
            'Resposta recebida do servidor.';
      } catch (_) {
        mensagem = 'O servidor respondeu com o código ${resposta.statusCode}.';
      }

      if (resposta.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Volta para a tela anterior, que deve ser o login.
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível conectar ao servidor. '
            'Verifique se o backend Java está funcionando.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  String? _obrigatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe $campo';
    }
    return null;
  }

  Widget _campo({
    required String rotulo,
    required String dica,
    required TextEditingController controller,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validador,
    bool senha = false,
    List<TextInputFormatter>? formatadores,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          obscureText: senha && _senhaOculta,
          inputFormatters: formatadores,
          maxLength: maxLength,
          validator: validador ??
              (valor) => _obrigatorio(valor, rotulo.toLowerCase()),
          decoration: InputDecoration(
            hintText: dica,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            suffixIcon: senha
                ? IconButton(
                    icon: Icon(
                      _senhaOculta
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaOculta = !_senhaOculta;
                      });
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _principal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _etapa == 1 ? 0.5 : 1,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: _principal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('$_etapa de 2'),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _etapa == 1 ? 'Crie sua conta' : 'Seus dados pessoais',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _principal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _etapa == 1
                      ? 'Preencha seus dados de acesso.'
                      : 'Informe seu CPF e endereço para concluir.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),

                        if (_etapa == 1) ...[
              _campo(
                rotulo: 'Nome',
                dica: 'Seu nome completo',
                controller: _nomeController,
              ),

             const SizedBox(height: 16),
                  _campo(
                    rotulo: 'E-mail',
                    dica: 'exemplo@email.com',
                    controller: _emailController,
                    teclado: TextInputType.emailAddress,
                    validador: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(valor.trim())) {
                        return 'Digite um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _campo(
                    rotulo: 'Senha',
                    dica: 'Mínimo de 6 caracteres',
                    controller: _senhaController,
                    senha: true,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Crie uma senha';
                      }
                      if (valor.length < 6) {
                        return 'Use pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  _campo(
                    rotulo: 'CPF',
                    dica: 'Somente números',
                    controller: _cpfController,
                    teclado: TextInputType.number,
                    formatadores: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: 11,
                    validador: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe seu CPF';
                      }
                      if (valor.length != 11) {
                        return 'O CPF deve ter 11 números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _campo(
                    rotulo: 'CEP',
                    dica: 'Somente números',
                    controller: _cepController,
                    teclado: TextInputType.number,
                    formatadores: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: 8,
                    validador: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe seu CEP';
                      }
                      if (valor.length != 8) {
                        return 'O CEP deve ter 8 números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _campo(
                    rotulo: 'Rua',
                    dica: 'Nome da rua ou avenida',
                    controller: _ruaController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _campo(
                          rotulo: 'Número',
                          dica: 'Nº',
                          controller: _numeroController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campo(
                          rotulo: 'Telefone',
                          dica: 'DDD + número',
                          controller: _telefoneController,
                          teclado: TextInputType.phone,
                          formatadores: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 11,
                          validador: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Informe o telefone';
                            }
                            if (valor.length < 10 || valor.length > 11) {
                              return 'Confira o telefone';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _carregando
                        ? null
                        : (_etapa == 1 ? _avancar : _cadastrar),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _principal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _etapa == 1 ? 'Próximo' : 'Finalizar cadastro',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (_etapa == 2) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _carregando ? null : _voltar,
                      child: const Text('Voltar'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _carregando
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Já possui uma conta? Entrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
