import 'dart:math';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout.dart' show formatarCnpjCpf, formatarChave, formatarValor, quebrar;
import 'dados_danfe_nfe.dart';

/// Opções do DANFE NF-e (A4 retrato).
class OpcoesDanfeNfe {
  const OpcoesDanfeNfe({
    this.cancelada = false,
    this.logo,
    this.margemMm = 5,
    this.exibirCanhoto = true,
  });

  /// Imprime a marca d'água "CANCELADA" (o app sabe pelo evento de cancelamento).
  final bool cancelada;

  /// Logo do emitente (PNG/JPEG).
  final Uint8List? logo;
  final double margemMm;
  final bool exibirCanhoto;
}

// Alturas (pt) usadas na paginação.
const _hCampo = 20.0;
const _hTitulo = 9.0;
const _hCanhoto = 42.0;
const _hSeparadorCanhoto = 6.0;
const _hCabecalhoTopo = 100.0;
const _hLinhaItem = 16.0;
const _hCabecalhoItens = 16.0;
const _hDadosAdicionais = 62.0;

/// Gera o DANFE NF-e em PDF A4, paginado com cabeçalho completo em cada folha.
Future<Uint8List> renderizarDanfeNfe(DadosDanfeNfe d, OpcoesDanfeNfe o) async {
  final margem = o.margemMm * PdfPageFormat.mm;
  final formato = PdfPageFormat.a4.copyWith(
      marginLeft: margem, marginRight: margem, marginTop: margem, marginBottom: margem);
  final alturaUtil = formato.availableHeight;

  final itens = d.itens;
  final temFatura = d.duplicatas.isNotEmpty;
  final cabecalho = _hCabecalhoTopo + 2 * _hCampo;
  final fixoPrimeira = (o.exibirCanhoto ? _hCanhoto + _hSeparadorCanhoto : 0) +
      cabecalho +
      (_hTitulo + 3 * _hCampo) + // destinatário
      (temFatura ? _hTitulo + 22 : 0) +
      (_hTitulo + 2 * _hCampo) + // imposto
      (_hTitulo + 3 * _hCampo) + // transportador
      (_hTitulo + _hCabecalhoItens) +
      (_hTitulo + _hDadosAdicionais) +
      4;
  final fixoDemais = cabecalho + _hTitulo + _hCabecalhoItens + 2;
  final cap1 = max(1, ((alturaUtil - fixoPrimeira) / _hLinhaItem).floor());
  final capN = max(1, ((alturaUtil - fixoDemais) / _hLinhaItem).floor());

  final paginas = <List<ItemDanfeNfe>>[];
  paginas.add(itens.take(cap1).toList());
  for (var i = cap1; i < itens.length; i += capN) {
    paginas.add(itens.skip(i).take(capN).toList());
  }
  final totalFolhas = paginas.length;

  final logo = o.logo == null ? null : pw.MemoryImage(o.logo!);
  final marca = o.cancelada
      ? 'CANCELADA'
      : d.homologacao
          ? 'SEM VALOR FISCAL'
          : d.protocolo == null
              ? 'SEM VALOR FISCAL'
              : null;

  final doc = pw.Document(title: 'DANFE NF-e ${d.numero}', creator: 'dfe_dart');
  for (var p = 0; p < totalFolhas; p++) {
    final primeira = p == 0;
    doc.addPage(pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: formato,
        theme: pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
        buildBackground: marca == null ? null : (_) => _marcaDagua(marca),
      ),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        if (primeira && o.exibirCanhoto) ...[_canhoto(d), _separadorCanhoto()],
        ..._cabecalho(d, logo, p + 1, totalFolhas),
        if (primeira) ...[
          ..._destinatario(d),
          if (temFatura) ..._fatura(d),
          ..._imposto(d),
          ..._transportador(d),
        ],
        _titulo('DADOS DOS PRODUTOS / SERVIÇOS'),
        _cabecalhoItens(),
        for (final it in paginas[p]) _linhaItem(it),
        if (primeira) ...[pw.Spacer(), ..._dadosAdicionais(d)],
      ]),
    ));
  }
  return doc.save();
}

// --- Componentes -----------------------------------------------------------------

const _borda = pw.BorderSide(width: 0.5);

pw.Widget _titulo(String s) => pw.Container(
      height: _hTitulo,
      alignment: pw.Alignment.bottomLeft,
      child: pw.Text(s, style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _campo(String rotulo, String valor,
        {int flex = 10, bool direita = false, bool negrito = false, double altura = _hCampo, double fonte = 7.5}) =>
    pw.Expanded(
      flex: flex,
      child: pw.Container(
        height: altura,
        padding: const pw.EdgeInsets.fromLTRB(2, 1, 2, 1),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Text(rotulo, style: const pw.TextStyle(fontSize: 5), maxLines: 1),
          pw.Spacer(),
          pw.Text(valor,
              maxLines: 1,
              textAlign: direita ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(fontSize: fonte, fontWeight: negrito ? pw.FontWeight.bold : null)),
        ]),
      ),
    );

pw.Widget _linha(List<pw.Widget> campos) => pw.Row(children: campos);

String _v(double v) => formatarValor(v);
String _num(double v, int casas) {
  final s = v.toStringAsFixed(casas).split('.');
  final inteiro = s[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return casas == 0 ? inteiro : '$inteiro,${s[1]}';
}

String _data(DateTime? d) => d == null
    ? ''
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _hora(DateTime? d) => d == null
    ? ''
    : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
String _numeroFormatado(int n) {
  final s = n.toString().padLeft(9, '0');
  return '${s.substring(0, 3)}.${s.substring(3, 6)}.${s.substring(6)}';
}

String _cep(String c) => c.length == 8 ? '${c.substring(0, 5)}-${c.substring(5)}' : c;

pw.Widget _canhoto(DadosDanfeNfe d) => pw.SizedBox(
      height: _hCanhoto,
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Expanded(
          flex: 80,
          child: pw.Column(children: [
            pw.Container(
              height: _hCanhoto - _hCampo,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'RECEBEMOS DE ${d.emitente.nome} OS PRODUTOS/SERVIÇOS CONSTANTES DA NOTA FISCAL '
                'INDICADA AO LADO. VALOR TOTAL: R\$ ${_v(d.total('vNF'))}  '
                'DESTINATÁRIO: ${d.destinatario?.nome ?? ''}',
                style: const pw.TextStyle(fontSize: 6),
                maxLines: 2,
              ),
            ),
            _linha([
              _campo('DATA DE RECEBIMENTO', '', flex: 20),
              _campo('IDENTIFICAÇÃO E ASSINATURA DO RECEBEDOR', '', flex: 60),
            ]),
          ]),
        ),
        pw.Expanded(
          flex: 20,
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            alignment: pw.Alignment.center,
            child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Text('NF-e', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Nº ${_numeroFormatado(d.numero)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('SÉRIE ${d.serie.toString().padLeft(3, '0')}', style: const pw.TextStyle(fontSize: 8)),
            ]),
          ),
        ),
      ]),
    );

pw.Widget _separadorCanhoto() => pw.Container(
      height: _hSeparadorCanhoto,
      alignment: pw.Alignment.center,
      child: pw.Container(
        height: 0,
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed))),
      ),
    );

List<pw.Widget> _cabecalho(DadosDanfeNfe d, pw.ImageProvider? logo, int folha, int folhas) {
  final e = d.emitente;
  final protocolo = d.protocolo == null
      ? (d.contingencia ? 'EMITIDA EM CONTINGÊNCIA' : '')
      : '${d.protocolo} - ${_data(d.dataAutorizacao)} ${_hora(d.dataAutorizacao)}';
  return [
    pw.SizedBox(
      height: _hCabecalhoTopo,
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        // Emitente
        pw.Expanded(
          flex: 40,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text('IDENTIFICAÇÃO DO EMITENTE', style: const pw.TextStyle(fontSize: 5)),
              pw.SizedBox(height: 2),
              if (logo != null) pw.SizedBox(height: 30, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.Text(e.nome,
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(e.logradouro, style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
              pw.Text('${e.bairro} - CEP ${_cep(e.cep)}', style: const pw.TextStyle(fontSize: 6.5)),
              pw.Text('${e.municipio} - ${e.uf}${e.fone.isEmpty ? '' : '  Fone: ${e.fone}'}',
                  style: const pw.TextStyle(fontSize: 6.5)),
            ]),
          ),
        ),
        // Quadro DANFE
        pw.Expanded(
          flex: 18,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(children: [
              pw.Text('DANFE', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text('Documento Auxiliar da\nNota Fiscal Eletrônica',
                  textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6)),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                pw.Text('0 - ENTRADA\n1 - SAÍDA', style: const pw.TextStyle(fontSize: 6)),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 14,
                  height: 14,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Text(d.tipoOperacao,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ]),
              pw.SizedBox(height: 4),
              pw.Text('Nº ${_numeroFormatado(d.numero)}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('SÉRIE ${d.serie.toString().padLeft(3, '0')}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('FOLHA $folha/$folhas', style: const pw.TextStyle(fontSize: 7)),
            ]),
          ),
        ),
        // Código de barras e chave
        pw.Expanded(
          flex: 42,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Container(
              height: 36,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.code128(useCode128A: false, useCode128B: false),
                data: d.chave,
                drawText: false,
              ),
            ),
            pw.Row(children: [
              _campo('CHAVE DE ACESSO', formatarChave(d.chave), negrito: true, fonte: 7.5),
            ]),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(3),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Text(
                  'Consulta de autenticidade no portal nacional da NF-e\n'
                  'www.nfe.fazenda.gov.br/portal ou no site da Sefaz Autorizadora',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 6.5),
                ),
              ),
            ),
          ]),
        ),
      ]),
    ),
    _linha([
      _campo('NATUREZA DA OPERAÇÃO', d.naturezaOperacao, flex: 58),
      _campo('PROTOCOLO DE AUTORIZAÇÃO DE USO', protocolo, flex: 42, negrito: true),
    ]),
    _linha([
      _campo('INSCRIÇÃO ESTADUAL', e.ie, flex: 33),
      _campo('INSC. ESTADUAL DO SUBST. TRIBUT.', e.ieSt, flex: 33),
      _campo('CNPJ / CPF', formatarCnpjCpf(e.documento), flex: 34),
    ]),
  ];
}

List<pw.Widget> _destinatario(DadosDanfeNfe d) {
  final x = d.destinatario;
  String s(String Function(ParteDanfe) f) => x == null ? '' : f(x);
  return [
    _titulo('DESTINATÁRIO / REMETENTE'),
    _linha([
      _campo('NOME / RAZÃO SOCIAL', s((p) => p.nome), flex: 55),
      _campo('CNPJ / CPF', s((p) => formatarCnpjCpf(p.documento)), flex: 25),
      _campo('DATA DA EMISSÃO', _data(d.dataEmissao), flex: 20),
    ]),
    _linha([
      _campo('ENDEREÇO', s((p) => p.logradouro), flex: 45),
      _campo('BAIRRO / DISTRITO', s((p) => p.bairro), flex: 23),
      _campo('CEP', s((p) => _cep(p.cep)), flex: 12),
      _campo('DATA DA SAÍDA/ENTRADA', _data(d.dataSaida), flex: 20),
    ]),
    _linha([
      _campo('MUNICÍPIO', s((p) => p.municipio), flex: 35),
      _campo('FONE / FAX', s((p) => p.fone), flex: 18),
      _campo('UF', s((p) => p.uf), flex: 7),
      _campo('INSCRIÇÃO ESTADUAL', s((p) => p.ie), flex: 20),
      _campo('HORA DA SAÍDA/ENTRADA', _hora(d.dataSaida), flex: 20),
    ]),
  ];
}

List<pw.Widget> _fatura(DadosDanfeNfe d) => [
      _titulo('FATURA / DUPLICATAS'),
      pw.Container(
        height: 22,
        padding: const pw.EdgeInsets.all(2),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Wrap(spacing: 12, children: [
          for (final dup in d.duplicatas.take(8))
            pw.Text(
              'Nº ${dup.numero}  Venc. ${dup.vencimento.length == 10 ? '${dup.vencimento.substring(8)}/${dup.vencimento.substring(5, 7)}/${dup.vencimento.substring(0, 4)}' : dup.vencimento}  R\$ ${_v(dup.valor)}',
              style: const pw.TextStyle(fontSize: 6.5),
            ),
        ]),
      ),
    ];

List<pw.Widget> _imposto(DadosDanfeNfe d) {
  pw.Widget c(String r, String campo) => _campo(r, _v(d.total(campo)), direita: true);
  return [
    _titulo('CÁLCULO DO IMPOSTO'),
    _linha([
      c('BASE DE CÁLC. DO ICMS', 'vBC'),
      c('VALOR DO ICMS', 'vICMS'),
      c('BASE DE CÁLC. ICMS S.T.', 'vBCST'),
      c('VALOR DO ICMS SUBST.', 'vST'),
      c('V. IMP. IMPORTAÇÃO', 'vII'),
      c('VALOR DO PIS', 'vPIS'),
      _campo('V. TOTAL PRODUTOS', _v(d.total('vProd')), direita: true, negrito: true),
    ]),
    _linha([
      c('VALOR DO FRETE', 'vFrete'),
      c('VALOR DO SEGURO', 'vSeg'),
      c('DESCONTO', 'vDesc'),
      c('OUTRAS DESPESAS', 'vOutro'),
      c('VALOR TOTAL IPI', 'vIPI'),
      c('VALOR DA COFINS', 'vCOFINS'),
      _campo('V. TOTAL DA NOTA', _v(d.total('vNF')), direita: true, negrito: true),
    ]),
  ];
}

List<pw.Widget> _transportador(DadosDanfeNfe d) {
  final pesoB = double.tryParse(d.volume('pesoB'));
  final pesoL = double.tryParse(d.volume('pesoL'));
  final doc = d.transporta('CNPJ').isNotEmpty ? d.transporta('CNPJ') : d.transporta('CPF');
  return [
    _titulo('TRANSPORTADOR / VOLUMES TRANSPORTADOS'),
    _linha([
      _campo('NOME / RAZÃO SOCIAL', d.transporta('xNome'), flex: 33),
      _campo('FRETE', d.modalidadeFrete, flex: 18),
      _campo('CÓDIGO ANTT', d.veiculo('RNTC'), flex: 11),
      _campo('PLACA DO VEÍCULO', d.veiculo('placa'), flex: 12),
      _campo('UF', d.veiculo('UF'), flex: 5),
      _campo('CNPJ / CPF', formatarCnpjCpf(doc), flex: 21),
    ]),
    _linha([
      _campo('ENDEREÇO', d.transporta('xEnder'), flex: 45),
      _campo('MUNICÍPIO', d.transporta('xMun'), flex: 29),
      _campo('UF', d.transporta('UF'), flex: 5),
      _campo('INSCRIÇÃO ESTADUAL', d.transporta('IE'), flex: 21),
    ]),
    _linha([
      _campo('QUANTIDADE', d.volume('qVol'), flex: 14),
      _campo('ESPÉCIE', d.volume('esp'), flex: 18),
      _campo('MARCA', d.volume('marca'), flex: 18),
      _campo('NUMERAÇÃO', d.volume('nVol'), flex: 16),
      _campo('PESO BRUTO', pesoB == null ? '' : _num(pesoB, 3), flex: 17, direita: true),
      _campo('PESO LÍQUIDO', pesoL == null ? '' : _num(pesoL, 3), flex: 17, direita: true),
    ]),
  ];
}

// Colunas da tabela de produtos: (rótulo, flex, alinhado à direita)
const _colunas = <(String, int, bool)>[
  ('CÓDIGO', 9, false),
  ('DESCRIÇÃO DO PRODUTO / SERVIÇO', 30, false),
  ('NCM/SH', 7, false),
  ('CST', 4, false),
  ('CFOP', 4, false),
  ('UN', 4, false),
  ('QUANT.', 7, true),
  ('V. UNIT.', 8, true),
  ('V. TOTAL', 8, true),
  ('BC ICMS', 7, true),
  ('V. ICMS', 6, true),
  ('V. IPI', 6, true),
  ('% ICMS', 4, true),
  ('% IPI', 4, true),
];

pw.Widget _celula(String texto, int flex, bool direita,
        {double altura = _hLinhaItem, double fonte = 6, int linhas = 1, bool cabecalho = false}) =>
    pw.Expanded(
      flex: flex,
      child: pw.Container(
        height: altura,
        padding: const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
        alignment: cabecalho
            ? pw.Alignment.center
            : (direita ? pw.Alignment.topRight : pw.Alignment.topLeft),
        decoration: const pw.BoxDecoration(border: pw.Border(left: _borda, right: _borda)),
        child: pw.Text(texto,
            maxLines: linhas,
            textAlign: cabecalho ? pw.TextAlign.center : (direita ? pw.TextAlign.right : pw.TextAlign.left),
            style: pw.TextStyle(fontSize: fonte)),
      ),
    );

pw.Widget _cabecalhoItens() => pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Row(children: [
        for (final (r, f, _) in _colunas)
          _celula(r, f, false, altura: _hCabecalhoItens, fonte: 5, linhas: 2, cabecalho: true),
      ]),
    );

pw.Widget _linhaItem(ItemDanfeNfe it) {
  // Descrição em até 2 linhas (altura fixa para paginação previsível).
  final desc = quebrar(it.descricao, 46).take(2).join('\n');
  final valores = <String>[
    it.codigo,
    desc,
    it.ncm,
    it.cst,
    it.cfop,
    it.unidade,
    _num(it.quantidade, 4),
    _num(it.valorUnitario, 4),
    _v(it.valorTotal),
    _v(it.baseIcms),
    _v(it.valorIcms),
    _v(it.valorIpi),
    _num(it.aliquotaIcms, 2),
    _num(it.aliquotaIpi, 2),
  ];
  return pw.Container(
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.25))),
    child: pw.Row(children: [
      for (var i = 0; i < _colunas.length; i++)
        _celula(valores[i], _colunas[i].$2, _colunas[i].$3, linhas: i == 1 ? 2 : 1),
    ]),
  );
}

List<pw.Widget> _dadosAdicionais(DadosDanfeNfe d) {
  final textos = <String>[
    if (d.homologacao) 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL.',
    if (d.contingencia)
      'DANFE EMITIDO EM CONTINGÊNCIA (tpEmis ${d.tipoEmissao}). '
          'Justificativa: ${d.justificativaContingencia}',
    if (d.informacoesComplementares.isNotEmpty) d.informacoesComplementares,
    if (d.total('vTotTrib') > 0)
      'Valor aproximado dos tributos: R\$ ${_v(d.total('vTotTrib'))} (Lei 12.741/2012).',
  ];
  return [
    _titulo('DADOS ADICIONAIS'),
    pw.SizedBox(
      height: _hDadosAdicionais,
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Expanded(
          flex: 65,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(2),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('INFORMAÇÕES COMPLEMENTARES', style: const pw.TextStyle(fontSize: 5)),
              pw.Text(textos.join(' '), style: const pw.TextStyle(fontSize: 6.5), maxLines: 7),
            ]),
          ),
        ),
        pw.Expanded(
          flex: 35,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(2),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('RESERVADO AO FISCO', style: const pw.TextStyle(fontSize: 5)),
              pw.Text(d.informacoesFisco, style: const pw.TextStyle(fontSize: 6.5), maxLines: 7),
            ]),
          ),
        ),
      ]),
    ),
  ];
}

pw.Widget _marcaDagua(String texto) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: pi / 5,
          child: pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: texto.length > 10 ? 64 : 80,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor(0.85, 0.85, 0.85),
            ),
          ),
        ),
      ),
    );

