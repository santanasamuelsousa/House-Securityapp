// HOUSE SECURITY - Tela de análise de planta integrada ao Back-End

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------- Cores ----------
const azul = Color(0xFF1E3A8A);
const verde = Color(0xFF2E7D32);
const laranja = Color(0xFFF57C00);
const vermelho = Color(0xFFD32F2F);
const corRisco = {'ALTO': vermelho, 'MEDIO': laranja, 'BAIXO': verde};

// ---------- Dados do relatório ----------
class Ponto {
  final String local, texto, nivel; // nivel: ALTO, MEDIO ou BAIXO
  const Ponto(this.local, this.texto, this.nivel);
}

class Relatorio {
  final List<String> identificado, plano;
  final List<Ponto> pontos;
  final int nota; // de 0 a 10
  final String justificativa;

  const Relatorio({
    required this.identificado,
    required this.pontos,
    required this.plano,
    required this.nota,
    required this.justificativa,
  });

  // Transforma o JSON do back-end em objeto do Flutter
  factory Relatorio.fromJson(Map<String, dynamic> j) => Relatorio(
        identificado: List<String>.from(j['identificado'] ?? []),
        pontos: [
          for (final p in j['pontos'] ?? [])
            Ponto(
              '${p['local']}',
              '${p['descricao']}',
              '${p['nivel']}'.toUpperCase().replaceAll('É', 'E'),
            ),
        ],
        plano: List<String>.from(j['plano'] ?? []),
        nota: (num.tryParse('${j['nota']}') ?? 0).round().clamp(0, 10).toInt(),
        justificativa: '${j['justificativaNota'] ?? ''}',
      );
}

// ---------- Integração com Back-End ----------
const String urlBackend = 'http://localhost:8080';

Future<Relatorio> buscarRelatorio(String nome, Uint8List bytes) async {
  final pedido = http.MultipartRequest('POST', Uri.parse('$urlBackend/api/analise'))
    ..files.add(http.MultipartFile.fromBytes('arquivo', bytes, filename: nome));

  final resposta = await http.Response.fromStream(
    await pedido.send().timeout(const Duration(minutes: 3)),
  );

  if (resposta.statusCode != 200) {
    throw 'O servidor respondeu com status ${resposta.statusCode}';
  }

  var texto = utf8.decode(resposta.bodyBytes);

  if (texto.contains('{') && texto.contains('}')) {
    texto = texto.substring(texto.indexOf('{'), texto.lastIndexOf('}') + 1);
  }

  final Map<String, dynamic> j = jsonDecode(texto);

  if (j['erro'] != null) {
    throw '${j['erro']}';
  }

  return Relatorio.fromJson(j);
}

// ---------- App ----------
void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: azul),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const Tela(),
    ));

// Os 4 estados da tela
enum Estado { inicio, escolhido, carregando, resultado }

class Tela extends StatefulWidget {
  const Tela({super.key});
  @override
  State<Tela> createState() => _TelaState();
}

class _TelaState extends State<Tela> {
  Estado estado = Estado.inicio;
  PlatformFile? arquivo; // arquivo escolhido
  Uint8List? bytes; // conteúdo do arquivo
  Relatorio? relatorio; // resultado da IA
  String? erro; // mensagem de erro (se houver)

  Future<void> escolher() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final f = result.files.first;
      final extensao = f.extension?.toLowerCase() ?? '';
      final extensoesPermitidas = ['png', 'jpg', 'jpeg'];

      if (!extensoesPermitidas.contains(extensao)) {
        setState(() {
          erro = 'Formato (.$extensao) não permitido. Escolha PNG, JPG ou JPEG.';
        });
        return;
      }

      final dados = f.bytes;
      if (dados == null) {
        setState(() => erro = 'Não foi possível ler o arquivo selecionado.');
        return;
      }

      if (dados.length > 20 * 1024 * 1024) {
        setState(() => erro = 'Arquivo muito grande (máximo 20 MB).');
        return;
      }

      setState(() {
        arquivo = f;
        bytes = dados;
        erro = null;
        estado = Estado.escolhido;
      });
    } catch (e) {
      setState(() => erro = 'Não foi possível abrir o arquivo: $e');
    }
  }

  void limpar() {
    setState(() {
      arquivo = null;
      bytes = null;
      relatorio = null;
      erro = null;
      estado = Estado.inicio;
    });
  }

  Future<void> analisar() async {
    setState(() {
      estado = Estado.carregando;
      erro = null;
    });
    try {
      final r = await buscarRelatorio(arquivo!.name, bytes!);
      if (!mounted) return;
      setState(() {
        relatorio = r;
        estado = Estado.resultado;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Não deu para analisar: $e';
        estado = Estado.escolhido;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('House Security', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: switch (estado) {
                Estado.inicio => telaInicio(),
                Estado.escolhido => telaEscolhido(),
                Estado.carregando => telaCarregando(),
                Estado.resultado => telaResultado(),
              },
            ),
          ),
        ),
      );

  // ---------- ESTADO 1: inicial ----------
  Widget telaInicio() => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Descubra os pontos fracos da sua casa',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Envie a planta da sua residência e mostramos as vulnerabilidades e o que fazer.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
        const SizedBox(height: 24),

        InkWell(
          onTap: escolher,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: azul.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: azul.withOpacity(0.4), width: 2),
            ),
            child: const Column(children: [
              Icon(Icons.cloud_upload_outlined, size: 56, color: azul),
              SizedBox(height: 12),
              Text('Toque para enviar a planta',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('PNG, JPG ou JPEG', style: TextStyle(color: Colors.grey)),
            ]),
          ),
        ),

        if (erro != null) mensagemErro(),
        const SizedBox(height: 20),

        botao('Escolher arquivo', Icons.folder_open_outlined, escolher),
      ]);

  // ---------- ESTADO 2: arquivo escolhido ----------
  Widget telaEscolhido() => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Confira a sua planta',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.memory(bytes!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 10),
        Text('${arquivo!.name} · ${(bytes!.length / 1024).round()} KB',
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
                onPressed: escolher,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Trocar')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: limpar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remover'),
              style: OutlinedButton.styleFrom(foregroundColor: vermelho),
            ),
          ),
        ]),
        if (erro != null) mensagemErro(),
        const SizedBox(height: 16),
        botao('Analisar Planta', Icons.auto_awesome, analisar),
      ]);

  // ---------- ESTADO 3: carregando ----------
  Widget telaCarregando() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 6, color: azul)),
            SizedBox(height: 28),
            Text('Estamos analisando sua planta residencial...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Isso pode levar até 1 minuto. Não feche o aplicativo.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );

  // ---------- ESTADO 4: resultado ----------
  Widget telaResultado() {
    final r = relatorio!;
    final corNota = r.nota >= 7 ? verde : (r.nota >= 4 ? laranja : vermelho);

    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Relatório de segurança',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      secao(Icons.home_work_outlined, 'O que foi identificado', azul, [
        for (final t in r.identificado) linha(Icons.check_circle_outline, azul, t),
      ]),
      secao(Icons.warning_amber_rounded, 'Pontos vulneráveis', vermelho, [
        for (final p in r.pontos) cartaoPonto(p),
      ]),
      secao(Icons.assignment_turned_in_outlined, 'Plano de ação', verde, [
        for (var i = 0; i < r.plano.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: verde,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(r.plano[i])),
            ]),
          ),
      ]),
      secao(Icons.shield_outlined, 'Nota de segurança', azul, [
        Row(children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: r.nota / 10,
                  strokeWidth: 9,
                  color: corNota,
                  backgroundColor: corNota.withOpacity(0.15),
                ),
              ),
              Text('${r.nota}/10',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: corNota)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(r.justificativa)),
        ]),
      ]),
      const SizedBox(height: 6),
      botao('Analisar outra planta', Icons.refresh, limpar),
    ]);
  }

  // ---------- Componentes Reutilizáveis ----------
  Widget mensagemErro() => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(erro!, style: const TextStyle(color: vermelho)),
      );
}

Widget botao(String texto, IconData icone, VoidCallback aoTocar) => FilledButton.icon(
      onPressed: aoTocar,
      icon: Icon(icone),
      label: Text(texto),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: azul,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

Widget secao(IconData icone, String titulo, Color cor, List<Widget> filhos) => Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, color: cor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          ...filhos,
        ]),
      ),
    );

Widget linha(IconData icone, Color cor, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 20, color: cor),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ]),
    );

Widget cartaoPonto(Ponto p) {
  final cor = corRisco[p.nivel] ?? Colors.grey;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cor.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cor.withOpacity(0.4)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
          child: Text(p.nivel == 'MEDIO' ? 'MÉDIO' : p.nivel,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(p.local, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 6),
      Text(p.texto),
    ]),
  );
}
