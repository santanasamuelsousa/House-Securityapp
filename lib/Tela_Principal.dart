import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const azul = Color(0xFF1E3A8A);
const limiteArquivo = 20 * 1024 * 1024; // 20 MB
const urlBackend = 'http://localhost:8080/api/analise';

class Tela extends StatefulWidget {
  const Tela({super.key});

  @override
  State<Tela> createState() => _TelaState();
}

class _TelaState extends State<Tela> {
  PlatformFile? arquivo;
  Uint8List? imagemBytes;
  String? erro;
  String? relatorio;
  bool selecionando = false;
  bool analisando = false;

  Future<void> escolherImagem() async {
    try {
      setState(() {
        selecionando = true;
        erro = null;
        relatorio = null;
      });

      final selecionado = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (!mounted) return;

      if (selecionado == null) {
        setState(() => selecionando = false);
        return;
      }

      final extensao = selecionado.extension?.toLowerCase() ?? '';
      const extensoesPermitidas = ['png', 'jpg', 'jpeg'];

      if (!extensoesPermitidas.contains(extensao)) {
        setState(() {
          selecionando = false;
          erro = 'Formato não permitido. Escolha PNG, JPG ou JPEG.';
        });
        return;
      }

      final tamanho = await selecionado.length();

      if (tamanho != null && tamanho > limiteArquivo) {
        setState(() {
          selecionando = false;
          erro = 'A imagem deve ter no máximo 20 MB.';
        });
        return;
      }

      final dados = await selecionado.readAsBytes();

      if (!mounted) return;

      if (dados.length > limiteArquivo) {
        setState(() {
          selecionando = false;
          erro = 'A imagem deve ter no máximo 20 MB.';
        });
        return;
      }

      setState(() {
        arquivo = selecionado;
        imagemBytes = dados;
        selecionando = false;
        erro = null;
        relatorio = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selecionando = false;
        erro = 'Não foi possível abrir a imagem: $e';
      });
    }
  }

  Future<void> analisarPlanta() async {
    if (imagemBytes == null || arquivo == null) return;

    setState(() {
      analisando = true;
      erro = null;
      relatorio = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(urlBackend));
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          imagemBytes!,
          filename: arquivo!.name,
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> jsonResp = jsonDecode(responseBody);

      if (!mounted) return;

      if (streamedResponse.statusCode == 200) {
        setState(() {
          relatorio = jsonResp['relatorio']?.toString() ?? 'Análise concluída.';
          analisando = false;
        });
      } else {
        setState(() {
          erro = jsonResp['mensagem']?.toString() ??
              'Erro ao analisar a planta (código ${streamedResponse.statusCode}).';
          analisando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        analisando = false;
        erro = 'Falha na comunicação com o servidor. Verifique se o back-end está ativo.';
      });
    }
  }

  void removerImagem() {
    setState(() {
      arquivo = null;
      imagemBytes = null;
      erro = null;
      relatorio = null;
    });
  }

  String formatarTamanho(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'House Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Análise da planta residencial',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione a planta da sua residência para '
                  'realizar a análise de segurança com IA.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),

                if (imagemBytes == null)
                  _areaSelecao()
                else
                  _imagemSelecionada(),

                if (erro != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      erro!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],

                if (relatorio != null) ...[
                  const SizedBox(height: 24),
                  _cardRelatorio(),
                ],

                const SizedBox(height: 24),

                if (imagemBytes != null) ...[
                  FilledButton.icon(
                    onPressed: analisando ? null : analisarPlanta,
                    icon: analisando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.security),
                    label: Text(
                      analisando ? 'Analisando planta...' : 'Analisar planta com IA',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: azul,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: analisando ? null : removerImagem,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                const Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: azul),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Formatos aceitos: PNG, JPG e JPEG. '
                            'Tamanho máximo: 20 MB.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _areaSelecao() {
    return InkWell(
      onTap: selecionando ? null : escolherImagem,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 45,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: azul.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            if (selecionando)
              const CircularProgressIndicator(color: azul)
            else
              const Icon(
                Icons.cloud_upload_outlined,
                size: 60,
                color: azul,
              ),
            const SizedBox(height: 16),
            Text(
              selecionando
                  ? 'Abrindo arquivos...'
                  : 'Selecione a planta da sua residência',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selecionando
                  ? 'Aguarde um momento.'
                  : 'Clique aqui para procurar uma imagem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (!selecionando) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: escolherImagem,
                icon: const Icon(Icons.folder_open),
                label: const Text('Escolher imagem'),
                style: FilledButton.styleFrom(
                  backgroundColor: azul,
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imagemSelecionada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Planta selecionada',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imagemBytes!,
              height: 320,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          arquivo!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          formatarTamanho(imagemBytes!.length),
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: (selecionando || analisando) ? null : escolherImagem,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Trocar imagem'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  Widget _cardRelatorio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: azul.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: azul),
              SizedBox(width: 8),
              Text(
                'Resultado da Análise de Segurança',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: azul,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          SelectableText(
            relatorio!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}