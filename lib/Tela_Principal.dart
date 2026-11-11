
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

const azul = Color(0xFF1E3A8A);
const limiteArquivo = 20 * 1024 * 1024; // 20 MB

class Tela extends StatefulWidget {
  const Tela({super.key});

  @override
  State<Tela> createState() => _TelaState();
}

class _TelaState extends State<Tela> {
  PlatformFile? arquivo;
  Uint8List? imagemBytes;
  String? erro;
  bool selecionando = false;

  Future<void> escolherImagem() async {
    try {
      setState(() {
        selecionando = true;
        erro = null;
      });

      final selecionado = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (!mounted) return;

      // O usuário cancelou a seleção.
      if (selecionado == null) {
        setState(() => selecionando = false);
        return;
      }

      // Verifica a extensão.
      final extensao = selecionado.extension?.toLowerCase() ?? '';
      const extensoesPermitidas = ['png', 'jpg', 'jpeg'];

      if (!extensoesPermitidas.contains(extensao)) {
        setState(() {
          selecionando = false;
          erro = 'Formato não permitido. Escolha PNG, JPG ou JPEG.';
        });
        return;
      }

      // Verifica o tamanho antes de carregar a imagem.
      final tamanho = await selecionado.length();

      if (tamanho != null && tamanho > limiteArquivo) {
        setState(() {
          selecionando = false;
          erro = 'A imagem deve ter no máximo 20 MB.';
        });
        return;
      }

      // Lê o conteúdo da imagem.
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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selecionando = false;
        erro = 'Não foi possível abrir a imagem: $e';
      });
    }
  }

  void removerImagem() {
    setState(() {
      arquivo = null;
      imagemBytes = null;
      erro = null;
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
                  'prepará-la para a análise de segurança.',
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
                  Text(
                    erro!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (imagemBytes != null)
                  OutlinedButton.icon(
                    onPressed: removerImagem,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),

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

                const SizedBox(height: 16),

                const Text(
                  'A integração com o serviço de análise será '
                  'implementada posteriormente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
          onPressed: selecionando ? null : escolherImagem,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Trocar imagem'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}
