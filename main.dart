import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const chave = String.fromEnvironment('GEMINI_KEY');
const modelos = ['gemini-3-flash-preview', 'gemini-2.5-flash', 'gemini-2.5-flash-lite'];
const prompt = 'Você é especialista em segurança residencial. Analise esta planta baixa e responda só em JSON: '
    '{"nivel": 0 (crítico), 1 (atenção) ou 2 (protegido), '
    '"recomendacoes": [ações práticas e curtas em português, cada uma citando o cômodo ou ponto da planta]}';
const cores = [Color(0xFFE0603C), Color(0xFFF2A93B), Color(0xFF3E8E6B)];
const niveis = ['Crítico', 'Atenção', 'Protegido'];

class Analise {
  final String nome;
  final int nivel;
  final List<String> recs;
  final Uint8List foto;
  Analise(this.nome, this.nivel, this.recs, this.foto);
}

Future<Analise> analisarPlanta(String nome, Uint8List foto) async {
  if (chave.isEmpty) throw 'chave do Gemini não configurada. Rode com --dart-define=GEMINI_KEY=sua_chave';
  http.Response? r;
  Object? falha;
  var usado = '';
  final base = chave.startsWith('AQ.')
      ? 'https://aiplatform.googleapis.com/v1/publishers/google/models'
      : 'https://generativelanguage.googleapis.com/v1beta/models';
  for (final m in modelos) {
    usado = m;
    try {
      r = await http
          .post(
            Uri.parse('$base/$m:generateContent?key=$chave'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'inlineData': {'mimeType': foto[0] == 0x89 ? 'image/png' : 'image/jpeg', 'data': base64Encode(foto)}},
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'responseMimeType': 'application/json'},
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (![503, 429, 404, 500].contains(r.statusCode)) break;
    } catch (e) {
      falha = e;
    }
    await Future.delayed(const Duration(seconds: 2));
  }
  if (r == null) throw 'sem resposta da IA: $falha';
  final corpo = jsonDecode(r.body);
  if (r.statusCode != 200) throw 'erro ${r.statusCode} no modelo $usado: ${corpo['error']?['message'] ?? r.body}';
  final cand = corpo['candidates'];
  if (cand == null || cand.isEmpty) throw 'a IA não devolveu resposta (${corpo['promptFeedback']?['blockReason'] ?? 'sem motivo'})';
  final j = jsonDecode(cand[0]['content']['parts'].map((p) => p['text'] ?? '').join());
  final n = (num.tryParse('${j['nivel']}') ?? 1).clamp(0, 2).toInt();
  return Analise(nome, n, [for (final e in j['recomendacoes']) '$e'], foto);
}

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2F3D))),
      home: const Home(),
    ));

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final lista = <Analise>[];

  Future<void> nova() async {
    final a = await Navigator.push<Analise>(context, MaterialPageRoute(builder: (_) => const NovaAnalise()));
    if (a != null && mounted) setState(() => lista.insert(0, a));
  }

  void avisos() {
    final c = lista.where((a) => a.nivel == 0).map((a) => a.nome);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(c.isEmpty ? 'Nenhum alerta' : 'Risco crítico: ${c.join(', ')}')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('House Security'), actions: [
          IconButton(onPressed: avisos, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () => setState(lista.clear), icon: const Icon(Icons.delete_outline)),
        ]),
        body: lista.isEmpty
            ? const Center(child: Text('Nenhuma análise ainda.\nToque em Nova análise.', textAlign: TextAlign.center))
            : ListView(children: [
                for (final a in lista)
                  ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Detalhe(a))),
                    onLongPress: () => setState(() => lista.remove(a)),
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8), child: Image.memory(a.foto, width: 56, height: 56, fit: BoxFit.cover)),
                    title: Text(a.nome),
                    subtitle: Text('${a.recs.length} pontos de atenção'),
                    trailing: Text(niveis[a.nivel], style: TextStyle(color: cores[a.nivel], fontWeight: FontWeight.w700)),
                  ),
              ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: nova,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Nova análise'),
        ),
      );
}

class NovaAnalise extends StatefulWidget {
  const NovaAnalise({super.key});

  @override
  State<NovaAnalise> createState() => _NovaAnaliseState();
}

class _NovaAnaliseState extends State<NovaAnalise> {
  final nome = TextEditingController();
  Uint8List? foto;
  bool carregando = false;
  String? erro;

  Future<void> escolher() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (f != null) foto = await f.readAsBytes();
    setState(() {});
  }

  Future<void> analisar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final a = await analisarPlanta(nome.text.trim(), foto!);
      if (mounted) Navigator.pop(context, a);
    } catch (e) {
      if (mounted) {
        setState(() {
          carregando = false;
          erro = 'Não deu pra analisar: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nova análise')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
            controller: nome,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nome do imóvel', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (foto != null) Image.memory(foto!, height: 200),
          OutlinedButton.icon(
            onPressed: carregando ? null : escolher,
            icon: const Icon(Icons.upload_file),
            label: Text(foto == null ? 'Escolher planta' : 'Trocar planta'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: nome.text.trim().isNotEmpty && foto != null && !carregando ? analisar : null,
            child: carregando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Analisar com IA'),
          ),
          if (erro != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(erro!, style: const TextStyle(color: Colors.red))),
        ]),
      );
}

class Detalhe extends StatelessWidget {
  final Analise a;
  const Detalhe(this.a, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(a.nome)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Image.memory(a.foto),
          const SizedBox(height: 12),
          Text('${niveis[a.nivel]} · ${a.recs.length} pontos',
              style: TextStyle(color: cores[a.nivel], fontWeight: FontWeight.w700, fontSize: 18)),
          for (final d in a.recs) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.shield_outlined), title: Text(d)),
        ]),
      );
}
