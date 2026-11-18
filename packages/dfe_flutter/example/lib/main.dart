import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:flutter/material.dart';
import 'package:dfe_nfe/dfe_nfe.dart';

import 'config.dart';
import 'danfe_page.dart';
import 'emissao.dart';

void main() => runApp(MaterialApp(
      title: 'dfe_dart - Homologação',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    ));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final cfg = ConfigApp.carregar();
  final _senha = TextEditingController();
  final _log = <String>[];
  bool _ocupado = false;
  CertificadoDigital? _cert;

  void _registrar(String m) {
    final h = TimeOfDay.now().format(context);
    setState(() => _log.insert(0, '[$h] $m'));
  }

  CertificadoDigital _certificado() {
    final c = _cert;
    if (c != null) return c;
    final novo = CertificadoDigital.dePfx(File(cfg.pfx).readAsBytesSync(), _senha.text);
    _registrar('Certificado: ${novo.nomeComum} (válido até ${novo.validoAte.toLocal()})');
    if (novo.vencido) _registrar('ATENÇÃO: certificado vencido.');
    if (cfg.cnpj.isEmpty && novo.documento?.length == 14) {
      cfg.cnpj = novo.documento!;
      cfg.salvar();
    }
    return _cert = novo;
  }

  Future<void> _executar(String titulo, Future<void> Function(EmissaoTeste e) acao) async {
    setState(() => _ocupado = true);
    _registrar('== $titulo');
    try {
      await acao(EmissaoTeste(cfg, _certificado(), _registrar));
    } on Pkcs12Exception catch (e) {
      _cert = null;
      _registrar('Erro no certificado: ${e.message}');
    } on ComunicacaoException catch (e) {
      _registrar('Erro de comunicação: ${e.message}');
    } catch (e) {
      _registrar('Erro: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('dfe_dart — NF-e / NFC-e em homologação'),
          bottom: const TabBar(
              tabs: [Tab(text: 'Emissão'), Tab(text: 'DANFE'), Tab(text: 'Configuração')]),
        ),
        body: TabBarView(children: [
          _abaEmissao(),
          DanfePage(cfg: cfg, log: _registrar),
          _abaConfig(),
        ]),
      ),
    );
  }

  Widget _abaEmissao() {
    Widget botao(String texto, IconData icone, Future<void> Function(EmissaoTeste) f) =>
        FilledButton.tonalIcon(
          onPressed: _ocupado ? null : () => _executar(texto, f),
          icon: Icon(icone),
          label: Text(texto),
        );

    Widget grupo(String titulo, List<Widget> botoes) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: botoes),
          ]),
        );

    final svc = Enderecador.contingenciaSvc(Uf.porSigla(cfg.uf));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _senha,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha do certificado (não é gravada)'),
              onChanged: (_) => _cert = null,
            ),
          ),
          const SizedBox(width: 16),
          Text('NF-e nº ${cfg.proximoNfe}  ·  NFC-e nº ${cfg.proximoNfce}'),
        ]),
        const SizedBox(height: 16),
        grupo('NF-e (modelo 55)', [
          botao('Status NF-e', Icons.wifi_tethering, (e) => e.status(ModeloDocumento.nfe)),
          botao('Emitir NF-e', Icons.send, (e) => e.emitir(ModeloDocumento.nfe)),
          botao('Status ${svc.name.toUpperCase()}', Icons.wifi_tethering,
              (e) => e.status(ModeloDocumento.nfe, tp: svc)),
          botao('Emitir NF-e em contingência (${svc.name.toUpperCase()})', Icons.warning_amber,
              (e) => e.emitir(ModeloDocumento.nfe, tp: svc)),
          botao('Consultar última NF-e', Icons.search, (e) => e.consultar(ModeloDocumento.nfe)),
          botao('Cancelar última NF-e', Icons.block, (e) => e.cancelarUltima(ModeloDocumento.nfe)),
        ]),
        grupo('NFC-e (modelo 65)', [
          botao('Status NFC-e', Icons.wifi_tethering, (e) => e.status(ModeloDocumento.nfce)),
          botao('Emitir NFC-e', Icons.send, (e) => e.emitir(ModeloDocumento.nfce)),
          botao('Emitir NFC-e offline (contingência)', Icons.cloud_off,
              (e) async => e.emitirNfceOffline()),
          botao('Transmitir NFC-e pendentes', Icons.cloud_upload, (e) => e.transmitirPendentes()),
          botao('Consultar última NFC-e', Icons.search, (e) => e.consultar(ModeloDocumento.nfce)),
          botao('Cancelar última NFC-e', Icons.block, (e) => e.cancelarUltima(ModeloDocumento.nfce)),
        ]),
        Row(children: [
          Expanded(child: Text('XMLs em: ${cfg.pastaXml}', overflow: TextOverflow.ellipsis)),
          TextButton.icon(
            onPressed: () {
              Directory(cfg.pastaXml).createSync(recursive: true);
              Process.run('explorer', [cfg.pastaXml]);
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Abrir pasta'),
          ),
          TextButton(onPressed: () => setState(_log.clear), child: const Text('Limpar log')),
        ]),
        const Divider(),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) => SelectableText(_log[i],
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _opcao(String rotulo, String valor, Map<String, String> opcoes, void Function(String) set) =>
      SizedBox(
        width: opcoes.values.any((t) => t.length > 22) ? 300 : 200,
        child: DropdownButtonFormField<String>(
          initialValue: opcoes.containsKey(valor) ? valor : opcoes.keys.first,
          decoration: InputDecoration(labelText: rotulo),
          items: [
            for (final e in opcoes.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => set(v!)),
        ),
      );

  Widget _abaConfig() {
    Widget campo(String rotulo, String valor, void Function(String) set,
            {double largura = 260, bool segredo = false}) =>
        SizedBox(
          width: largura,
          child: TextFormField(
            initialValue: valor,
            obscureText: segredo,
            decoration: InputDecoration(labelText: rotulo),
            onChanged: set,
          ),
        );
    int n(String s, int padrao) => int.tryParse(s.trim()) ?? padrao;

    Widget secao(String titulo, List<Widget> campos) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 16, runSpacing: 4, children: campos),
          ]),
        );

    return ListView(padding: const EdgeInsets.all(16), children: [
      secao('Certificado e saída', [
        campo('Caminho do .pfx', cfg.pfx, (v) {
          cfg.pfx = v.trim();
          _cert = null;
        }, largura: 540),
        campo('Pasta dos XMLs', cfg.pastaXml, (v) => cfg.pastaXml = v.trim(), largura: 540),
      ]),
      secao('Emitente', [
        campo('UF', cfg.uf, (v) => cfg.uf = v.trim().toUpperCase(), largura: 80),
        campo('CNPJ (vazio = do certificado)', cfg.cnpj, (v) => cfg.cnpj = v.trim()),
        campo('Inscrição Estadual', cfg.ie, (v) => cfg.ie = v.trim()),
        campo('CRT (1 SN, 4 MEI)', '${cfg.crt}', (v) => cfg.crt = n(v, 1), largura: 140),
        campo('Razão social', cfg.razaoSocial, (v) => cfg.razaoSocial = v, largura: 400),
        campo('Nome fantasia', cfg.nomeFantasia, (v) => cfg.nomeFantasia = v),
        campo('Logradouro', cfg.logradouro, (v) => cfg.logradouro = v, largura: 400),
        campo('Número', cfg.numero, (v) => cfg.numero = v, largura: 100),
        campo('Bairro', cfg.bairro, (v) => cfg.bairro = v),
        campo('Cód. município IBGE', '${cfg.codigoMunicipio}',
            (v) => cfg.codigoMunicipio = n(v, cfg.codigoMunicipio), largura: 180),
        campo('Município', cfg.municipio, (v) => cfg.municipio = v),
        campo('CEP', cfg.cep, (v) => cfg.cep = v.replaceAll(RegExp(r'\D'), ''), largura: 140),
      ]),
      secao('Numeração', [
        campo('Série NF-e', '${cfg.serieNfe}', (v) => cfg.serieNfe = n(v, 1), largura: 120),
        campo('Próximo nº NF-e', '${cfg.proximoNfe}', (v) => cfg.proximoNfe = n(v, 1), largura: 160),
        campo('Série NFC-e', '${cfg.serieNfce}', (v) => cfg.serieNfce = n(v, 1), largura: 120),
        campo('Próximo nº NFC-e', '${cfg.proximoNfce}', (v) => cfg.proximoNfce = n(v, 1), largura: 160),
      ]),
      secao('NFC-e (QR Code)', [
        campo('Versão (v2 ou v3)', cfg.versaoQr, (v) => cfg.versaoQr = v.trim(), largura: 160),
        campo('ID do CSC (v2)', cfg.idCsc, (v) => cfg.idCsc = v.trim(), largura: 160),
        campo('CSC (v2)', cfg.csc, (v) => cfg.csc = v.trim(), segredo: true),
      ]),
      secao('Cenário da venda de teste (2 itens: R\$ 10,00 + 2 × R\$ 12,50)', [
        _opcao('Tributação', cfg.tributacao, {
          'sn102': 'Simples - CSOSN 102',
          'sn101': 'Simples - CSOSN 101 (crédito 2,56%)',
          'normal00': 'Normal - CST 00 (ICMS 18%, PIS/COFINS)',
          'normal40': 'Normal - CST 40 (isenta)',
        }, (v) => cfg.tributacao = v),
        _opcao('Pagamento', cfg.pagamento, {
          'dinheiro': 'Dinheiro (com troco)',
          'credito': 'Cartão de crédito',
          'debito': 'Cartão de débito',
          'pix': 'PIX',
          'misto': 'Crédito + dinheiro',
        }, (v) => cfg.pagamento = v),
        campo('Desconto na venda (R\$, rateado)', cfg.desconto.toStringAsFixed(2),
            (v) => cfg.desconto = double.tryParse(v.replaceAll(',', '.')) ?? 0, largura: 220),
      ]),
      secao('Responsável técnico (infRespTec) — deixe o CNPJ vazio para não enviar', [
        campo('CNPJ', cfg.respTecCnpj, (v) => cfg.respTecCnpj = v.replaceAll(RegExp(r'\D'), '')),
        campo('Contato', cfg.respTecContato, (v) => cfg.respTecContato = v),
        campo('E-mail', cfg.respTecEmail, (v) => cfg.respTecEmail = v.trim()),
        campo('Fone', cfg.respTecFone, (v) => cfg.respTecFone = v.replaceAll(RegExp(r'\D'), ''),
            largura: 160),
      ]),
      secao('DANFE NFC-e e impressora (ESC/POS)', [
        _opcao('Papel', cfg.colunas <= 32 ? '58' : '80', {'80': '80 mm (48 col.)', '58': '58 mm (32 col.)'},
            (v) => cfg.colunas = v == '58' ? 32 : 48),
        _opcao('Item', cfg.itemDuasLinhas ? '2' : '1', {'1': 'Uma linha', '2': 'Duas linhas'},
            (v) => cfg.itemDuasLinhas = v == '2'),
        _opcao('QR Code', cfg.modoQr, {'nativo': 'Nativo (GS ( k)', 'imagem': 'Imagem raster'},
            (v) => cfg.modoQr = v),
        _opcao('Acentos', cfg.paginaCodigo,
            {'cp860': 'CP860', 'cp850': 'CP850', 'semAcento': 'Sem acento'}, (v) => cfg.paginaCodigo = v),
        _opcao('Corte', cfg.corte, {'parcial': 'Parcial', 'total': 'Total', 'nenhum': 'Sem corte'},
            (v) => cfg.corte = v),
        _opcao('Gaveta', cfg.abrirGaveta ? 's' : 'n', {'n': 'Não abrir', 's': 'Abrir'},
            (v) => cfg.abrirGaveta = v == 's'),
        campo('Impressora (nome no Windows)', cfg.impressora, (v) => cfg.impressora = v.trim(),
            largura: 400),
      ]),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () {
            cfg.salvar();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Configuração salva em ${ConfigApp.pastaApp.path}')));
          },
          icon: const Icon(Icons.save),
          label: const Text('Salvar configuração'),
        ),
      ),
    ]);
  }
}
