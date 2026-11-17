import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dfe_flutter/danfe_imagem.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'config.dart';
import 'impressao_windows.dart';

/// Documento gravado que pode gerar DANFE.
class _Documento {
  _Documento(this.arquivo, {required this.nfce, required this.pendente, required this.cancelada});
  final File arquivo;
  final bool nfce;
  final bool pendente;
  final bool cancelada;

  String get chave => arquivo.uri.pathSegments.last.substring(0, 44);
  String get situacao => [
        nfce ? 'NFC-e' : 'NF-e',
        if (pendente) 'contingência pendente' else 'autorizada',
        if (cancelada) 'CANCELADA',
      ].join(' · ');
}

/// Aba DANFE: escolhe uma NF-e/NFC-e gravada, pré-visualiza e exporta/imprime.
///
/// Mostra a divisão de responsabilidades: a biblioteca gera texto, PDF, PNG e
/// ESC/POS; o app escolhe como imprimir.
class DanfePage extends StatefulWidget {
  const DanfePage({super.key, required this.cfg, required this.log});

  final ConfigApp cfg;
  final void Function(String) log;

  @override
  State<DanfePage> createState() => _DanfePageState();
}

class _DanfePageState extends State<DanfePage> {
  List<_Documento> _docs = [];
  _Documento? _sel;
  List<Uint8List> _pngs = [];
  String? _erro;
  bool _ocupado = false;

  ConfigApp get cfg => widget.cfg;

  @override
  void initState() {
    super.initState();
    _listar();
  }

  void _listar() {
    final s = Platform.pathSeparator;
    final docs = <_Documento>[];
    for (final (pasta, sufixo, nfce, pendente) in [
      ('${cfg.pastaXml}${s}nfce', '-procNFe.xml', true, false),
      ('${cfg.pastaXml}${s}nfce${s}pendentes', '-nfe.xml', true, true),
      ('${cfg.pastaXml}${s}nfe', '-procNFe.xml', false, false),
    ]) {
      final d = Directory(pasta);
      if (!d.existsSync()) continue;
      for (final f in d.listSync().whereType<File>().where((f) => f.path.endsWith(sufixo))) {
        final chave = f.uri.pathSegments.last.substring(0, 44);
        final cancelada = File('$pasta$s$chave-110111-01-procEventoNFe.xml').existsSync();
        docs.add(_Documento(f, nfce: nfce, pendente: pendente, cancelada: cancelada));
      }
    }
    docs.sort((a, b) => b.arquivo.lastModifiedSync().compareTo(a.arquivo.lastModifiedSync()));
    setState(() => _docs = docs);
    if (docs.isNotEmpty && _sel == null) _selecionar(docs.first);
  }

  String get _xml => _sel!.arquivo.readAsStringSync();

  DanfeNfce _nfce() => DanfeNfce.deXml(_xml,
      opcoes: OpcoesDanfe(colunas: cfg.colunas, itemEmDuasLinhas: cfg.itemDuasLinhas));

  DanfeNfe _nfe() => DanfeNfe.deXml(_xml);
  OpcoesDanfeNfe get _opcoesNfe => OpcoesDanfeNfe(cancelada: _sel!.cancelada);

  OpcoesPdf get _opcoesPdf => OpcoesPdf(larguraMm: cfg.colunas <= 32 ? 58 : 80);

  OpcoesEscPos get _opcoesEscPos => OpcoesEscPos(
        modoQrCode: cfg.modoQr == 'imagem' ? ModoQrCode.imagem : ModoQrCode.nativo,
        paginaCodigo: switch (cfg.paginaCodigo) {
          'cp850' => PaginaCodigo.cp850,
          'semAcento' => PaginaCodigo.semAcento,
          _ => PaginaCodigo.cp860,
        },
        corte: switch (cfg.corte) {
          'total' => Corte.total,
          'nenhum' => Corte.nenhum,
          _ => Corte.parcial,
        },
        abrirGaveta: cfg.abrirGaveta,
      );

  Future<Uint8List> _pdf() => _sel!.nfce ? _nfce().pdf(_opcoesPdf) : _nfe().pdf(_opcoesNfe);

  Future<void> _selecionar(_Documento d) async {
    setState(() {
      _sel = d;
      _pngs = [];
      _erro = null;
    });
    try {
      final pngs = d.nfce
          ? [await _nfce().imagemPng(pdf: _opcoesPdf)]
          : await _nfe().imagensPng(opcoes: _opcoesNfe);
      if (mounted && _sel == d) setState(() => _pngs = pngs);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  String get _base {
    final p = _sel!.arquivo.path;
    return p.substring(0, p.lastIndexOf('-'));
  }

  Future<void> _acao(String nome, Future<void> Function() f) async {
    setState(() => _ocupado = true);
    try {
      await f();
    } catch (e) {
      widget.log('DANFE - $nome: erro: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _salvar(String ext, Future<List<int>> Function() gerar) =>
      _acao('salvar $ext', () async {
        final f = File('$_base-danfe.$ext');
        await f.writeAsBytes(await gerar());
        widget.log('DANFE salvo: ${f.path}');
      });

  Future<void> _salvarPngs() => _acao('salvar png', () async {
        for (var i = 0; i < _pngs.length; i++) {
          final f = File(_pngs.length == 1 ? '$_base-danfe.png' : '$_base-danfe-folha${i + 1}.png');
          await f.writeAsBytes(_pngs[i]);
          widget.log('DANFE salvo: ${f.path}');
        }
      });

  Future<void> _escolherImpressora() async {
    final lista = await Printing.listPrinters();
    if (!mounted) return;
    final escolhida = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Impressora para ESC/POS (RAW)'),
        children: [
          for (final p in lista)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, p.name),
              child: Text(p.name + (p.isDefault ? '  (padrão)' : '')),
            ),
        ],
      ),
    );
    if (escolhida != null) {
      setState(() => cfg.impressora = escolhida);
      cfg.salvar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _sel;
    final nfce = sel?.nfce ?? false;
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        width: 380,
        child: Column(children: [
          ListTile(
            title: const Text('Notas gravadas'),
            trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _listar),
          ),
          Expanded(
            child: _docs.isEmpty
                ? const Center(child: Text('Nenhuma nota. Emita uma na aba Emissão.'))
                : ListView(children: [
                    for (final d in _docs)
                      ListTile(
                        dense: true,
                        selected: d.arquivo.path == sel?.arquivo.path,
                        leading: Icon(d.nfce ? Icons.receipt : Icons.description_outlined),
                        title: Text(d.chave, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
                        subtitle: Text(d.situacao),
                        onTap: () => _selecionar(d),
                      ),
                  ]),
          ),
        ]),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        child: sel == null
            ? const SizedBox()
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(
                      onPressed: _ocupado
                          ? null
                          : () => _acao('imprimir PDF', () async {
                                final pdf = await _pdf();
                                await Printing.layoutPdf(
                                    onLayout: (_) => pdf, name: nfce ? 'DANFE NFC-e' : 'DANFE NF-e');
                              }),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir PDF (diálogo do Windows)'),
                    ),
                    if (nfce) ...[
                      FilledButton.tonalIcon(
                        onPressed: _ocupado || cfg.impressora.isEmpty
                            ? null
                            : () => _acao('imprimir ESC/POS', () async {
                                  imprimirRawWindows(cfg.impressora, _nfce().escPos(_opcoesEscPos));
                                  widget.log('ESC/POS enviado para "${cfg.impressora}"');
                                }),
                        icon: const Icon(Icons.receipt_long),
                        label: Text(cfg.impressora.isEmpty
                            ? 'Imprimir ESC/POS (escolha a impressora)'
                            : 'Imprimir ESC/POS em "${cfg.impressora}"'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _escolherImpressora,
                        icon: const Icon(Icons.settings),
                        label: const Text('Impressora'),
                      ),
                    ],
                    OutlinedButton(onPressed: () => _salvar('pdf', _pdf), child: const Text('Salvar PDF')),
                    OutlinedButton(
                        onPressed: _pngs.isEmpty ? null : _salvarPngs, child: const Text('Salvar PNG')),
                    if (nfce) ...[
                      OutlinedButton(
                          onPressed: () => _salvar('txt', () async => utf8.encode(_nfce().texto())),
                          child: const Text('Salvar TXT')),
                      OutlinedButton(
                          onPressed: () => _salvar('bin', () async => _nfce().escPos(_opcoesEscPos)),
                          child: const Text('Salvar ESC/POS (.bin)')),
                    ],
                  ]),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.topCenter,
                    child: _erro != null
                        ? Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $_erro'))
                        : _pngs.isEmpty
                            ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  for (final png in _pngs)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Material(
                                          elevation: 3,
                                          child: Image.memory(png,
                                              width: nfce ? 380 : 760, fit: BoxFit.fitWidth),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ),
              ]),
      ),
    ]);
  }
}
