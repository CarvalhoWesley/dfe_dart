import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dfe_flutter/danfe_imagem.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'config.dart';
import 'impressao_windows.dart';

/// Aba DANFE: escolhe uma NFC-e gravada, pré-visualiza e exporta/imprime.
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
  List<File> _arquivos = [];
  File? _selecionado;
  Uint8List? _png;
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
    final arquivos = <File>[];
    for (final (pasta, sufixo) in [
      ('${cfg.pastaXml}${s}nfce', '-procNFe.xml'),
      ('${cfg.pastaXml}${s}nfce${s}pendentes', '-nfe.xml'),
    ]) {
      final d = Directory(pasta);
      if (!d.existsSync()) continue;
      arquivos.addAll(d.listSync().whereType<File>().where((f) => f.path.endsWith(sufixo)));
    }
    arquivos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() => _arquivos = arquivos);
    if (arquivos.isNotEmpty && _selecionado == null) _selecionar(arquivos.first);
  }

  DanfeNfce _danfe() => DanfeNfce.deXml(
        _selecionado!.readAsStringSync(),
        opcoes: OpcoesDanfe(colunas: cfg.colunas, itemEmDuasLinhas: cfg.itemDuasLinhas),
      );

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

  Future<void> _selecionar(File f) async {
    setState(() {
      _selecionado = f;
      _png = null;
      _erro = null;
    });
    try {
      final png = await _danfe().imagemPng(pdf: _opcoesPdf);
      if (mounted && _selecionado == f) setState(() => _png = png);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  String get _base {
    final p = _selecionado!.path;
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

  Future<void> _salvar(String ext, Future<List<int>> Function() gerar) => _acao('salvar $ext', () async {
        final f = File('$_base-danfe.$ext');
        await f.writeAsBytes(await gerar());
        widget.log('DANFE salvo: ${f.path}');
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
    final sel = _selecionado;
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        width: 380,
        child: Column(children: [
          ListTile(
            title: const Text('NFC-e gravadas'),
            trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _listar),
          ),
          Expanded(
            child: _arquivos.isEmpty
                ? const Center(child: Text('Nenhuma NFC-e. Emita uma na aba Emissão.'))
                : ListView(children: [
                    for (final f in _arquivos)
                      ListTile(
                        dense: true,
                        selected: f.path == sel?.path,
                        title: Text(f.uri.pathSegments.last.substring(0, 44),
                            style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
                        subtitle: Text(f.path.contains('pendentes') ? 'Contingência pendente' : 'Autorizada'),
                        onTap: () => _selecionar(f),
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
                                final pdf = await _danfe().pdf(_opcoesPdf);
                                await Printing.layoutPdf(onLayout: (_) => pdf, name: 'DANFE NFC-e');
                              }),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir PDF (diálogo do Windows)'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _ocupado || cfg.impressora.isEmpty
                          ? null
                          : () => _acao('imprimir ESC/POS', () async {
                                imprimirRawWindows(cfg.impressora, _danfe().escPos(_opcoesEscPos));
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
                    OutlinedButton(
                        onPressed: () => _salvar('pdf', () => _danfe().pdf(_opcoesPdf)),
                        child: const Text('Salvar PDF')),
                    OutlinedButton(
                        onPressed: () => _salvar('png', () => _danfe().imagemPng(pdf: _opcoesPdf)),
                        child: const Text('Salvar PNG')),
                    OutlinedButton(
                        onPressed: () => _salvar('txt', () async => utf8.encode(_danfe().texto())),
                        child: const Text('Salvar TXT')),
                    OutlinedButton(
                        onPressed: () => _salvar('bin', () async => _danfe().escPos(_opcoesEscPos)),
                        child: const Text('Salvar ESC/POS (.bin)')),
                  ]),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.topCenter,
                    child: _erro != null
                        ? Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $_erro'))
                        : _png == null
                            ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Material(
                                  elevation: 3,
                                  child: Image.memory(_png!, width: 380, fit: BoxFit.fitWidth),
                                ),
                              ),
                  ),
                ),
              ]),
      ),
    ]);
  }
}
