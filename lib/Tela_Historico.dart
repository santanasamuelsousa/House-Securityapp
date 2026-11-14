import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const azul = Color(0xFF1E3A8A);
const urlListagem = 'http://localhost:8080/api/analises';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  List analises = [];
  Map? analiseSelecionada;
  bool carregando = true;
  int? idExcluindo;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final response = await http.get(Uri.parse(urlListagem));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List dados = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          analises = dados;
          analiseSelecionada = analises.isNotEmpty ? analises.first : null;
          carregando = false;
        });
      } else {
        setState(() {
          erro = 'Erro ao carregar histórico (${response.statusCode}).';
          carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Falha ao conectar com o servidor.';
        carregando = false;
      });
    }
  }

  Future<void> confirmarExclusao(Map item) async {
    final int? id = int.tryParse(item['idAtestado']?.toString() ?? '');
    if (id == null) return;

    final idTexto = id.toString().padLeft(2, '0');

    final confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir relatório'),
        content: Text('Deseja excluir o relatório #$idTexto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    setState(() => idExcluindo = id);

    try {
      final response = await http.delete(Uri.parse('$urlListagem/$id'));
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          analises.removeWhere((a) => a['idAtestado'] == item['idAtestado']);
          if (analiseSelecionada?['idAtestado'] == item['idAtestado']) {
            analiseSelecionada = analises.isNotEmpty ? analises.first : null;
          }
          idExcluindo = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Relatório #$idTexto excluído.')),
        );
      } else {
        setState(() => idExcluindo = null);
      }
    } catch (e) {
      if (mounted) setState(() => idExcluindo = null);
    }
  }

  String formatarData(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  String gerarResumo(String? texto) {
    final linhas = (texto ?? '')
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[#*>\-]'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (linhas.length > 1 && linhas.first.startsWith('1)')) return linhas[1];
    return linhas.isNotEmpty ? linhas.first : 'Análise de planta';
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
          'Histórico de Análises',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: carregando ? null : carregarHistorico,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Planilha de Relatórios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Toque em uma linha para abrir o laudo.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: azul.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${analises.length} registros',
                        style: const TextStyle(
                          color: azul,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (carregando)
                  const Center(child: CircularProgressIndicator(color: azul))
                else if (erro != null)
                  Text(erro!, style: const TextStyle(color: Colors.red))
                else if (analises.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma análise salva ainda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  _tabelaPlanilha(),
                  if (analiseSelecionada != null) ...[
                    const SizedBox(height: 16),
                    _cardRelatorio(analiseSelecionada!),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabelaPlanilha() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              color: azul.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: const Row(
                children: [
                  SizedBox(width: 34, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: azul, fontSize: 12))),
                  SizedBox(width: 72, child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold, color: azul, fontSize: 12))),
                  Expanded(child: Text('Resumo', style: TextStyle(fontWeight: FontWeight.bold, color: azul, fontSize: 12))),
                  SizedBox(width: 72, child: Text('Ações', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: azul, fontSize: 12))),
                ],
              ),
            ),
            ...analises.map((item) {
              final id = item['idAtestado']?.toString().padLeft(2, '0') ?? '--';
              final selecionado = analiseSelecionada?['idAtestado'] == item['idAtestado'];

              return InkWell(
                onTap: () => setState(() => analiseSelecionada = item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: selecionado ? azul.withOpacity(0.06) : Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                      left: BorderSide(color: selecionado ? azul : Colors.transparent, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 34, child: Text('#$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                      SizedBox(width: 72, child: Text(formatarData(item['criacao']?.toString()), style: const TextStyle(fontSize: 12))),
                      Expanded(
                        child: Text(
                          gerarResumo(item['analiseIa']?.toString()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selecionado ? azul : azul.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Ver',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: selecionado ? Colors.white : azul,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (idExcluindo == item['idAtestado'])
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              GestureDetector(
                                onTap: () => confirmarExclusao(item),
                                child: const Icon(Icons.delete_outline, color: Colors.red, size: 19),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _cardRelatorio(Map item) {
    final id = item['idAtestado']?.toString().padLeft(2, '0') ?? '--';
    final data = formatarData(item['criacao']?.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: azul.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: azul),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laudo Técnico #$id ($data)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azul),
                ),
              ),
              IconButton(
                onPressed: () => confirmarExclusao(item),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 20),
          construirLaudoVisual(item['analiseIa']?.toString() ?? ''),
        ],
      ),
    );
  }
}

// Formata o texto da IA nas duas telas sem símbolos de Markdown (** ou #)
Widget construirLaudoVisual(String texto) {
  final linhas = texto.split('\n');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: linhas.map((linhaBruta) {
      final linha = linhaBruta.replaceAll('**', '').replaceAll('#', '').trim();
      if (linha.isEmpty) return const SizedBox(height: 6);

      // Títulos das seções: 1), 2), 3), 4)
      if (RegExp(r'^\d+\)').hasMatch(linha)) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: azul.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            linha,
            style: const TextStyle(fontWeight: FontWeight.bold, color: azul, fontSize: 13.5),
          ),
        );
      }

      // Destaque da Nota final
      if (linha.toLowerCase().startsWith('nota:')) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4, bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: azul,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            linha,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SelectableText(
          linha,
          style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade800),
        ),
      );
    }).toList(),
  );
}