import 'dart:math';

import '../enums.dart';
import '../status/cons_stat_serv.dart' show nsNfe;
import '../util/chave_acesso.dart';
import '../util/formatacao.dart';
import 'dados_nfe.dart';

const textoHomologacaoItem =
    'NOTA FISCAL EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL';
const textoHomologacaoDest = 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL';

/// Resultado da montagem: XML do `<NFe>` (sem assinatura) e a chave gerada.
class NfeMontada {
  NfeMontada(this.xml, this.chave);
  final String xml;
  final ChaveAcesso chave;
}

/// Monta o XML `<NFe>` 4.00 a partir de [DadosNfe].
///
/// Em homologação aplica as regras da SEFAZ: descrição do 1º item e nome do
/// destinatário com o texto "SEM VALOR FISCAL".
NfeMontada montarNfe(DadosNfe d, {Random? random}) {
  final rnd = random ?? Random.secure();
  var cnf = d.codigoNumerico ?? (rnd.nextInt(99999998) + 1);
  if (cnf == d.numero) cnf = (cnf + 1) % 100000000;

  final uf = d.emitente.endereco.uf;
  final chave = ChaveAcesso.gerar(
    uf: uf,
    dataEmissao: d.dataEmissao,
    cnpj: d.emitente.cnpj,
    modelo: d.modelo,
    serie: d.serie,
    numero: d.numero,
    tipoEmissao: d.tipoEmissao,
    codigoNumerico: cnf,
  );

  final hom = d.ambiente == Ambiente.homologacao;
  final nfce = d.modelo == ModeloDocumento.nfce;
  final x = StringBuffer()
    ..write('<NFe xmlns="$nsNfe"><infNFe versao="4.00" Id="${chave.id}">');

  // ide
  x
    ..write('<ide>')
    ..write(_t('cUF', '${uf.codigo}'))
    ..write(_t('cNF', chave.codigoNumerico))
    ..write(_t('natOp', d.naturezaOperacao))
    ..write(_t('mod', '${d.modelo.codigo}'))
    ..write(_t('serie', '${d.serie}'))
    ..write(_t('nNF', '${d.numero}'))
    ..write(_t('dhEmi', formatarDataHora(d.dataEmissao)))
    ..write(_t('tpNF', '1'))
    ..write(_t('idDest', '1'))
    ..write(_t('cMunFG', '${d.emitente.endereco.codigoMunicipio}'))
    ..write(_t('tpImp', nfce ? '4' : '1'))
    ..write(_t('tpEmis', '${d.tipoEmissao.codigo}'))
    ..write(_t('cDV', '${chave.digitoVerificador}'))
    ..write(_t('tpAmb', '${d.ambiente.codigo}'))
    ..write(_t('finNFe', '1'))
    ..write(_t('indFinal', '1'))
    ..write(_t('indPres', '1'))
    ..write(_t('procEmi', '0'))
    ..write(_t('verProc', d.versaoAplicativo));
  if (d.tipoEmissao.contingencia) {
    final just = d.justificativaContingencia ?? '';
    if (just.length < 15) {
      throw ArgumentError('Justificativa de contingência deve ter ao menos 15 caracteres');
    }
    x
      ..write(_t('dhCont', formatarDataHora(d.dataContingencia!)))
      ..write(_t('xJust', just));
  }
  x.write('</ide>');

  // emit
  final e = d.emitente;
  x
    ..write('<emit>')
    ..write(_t('CNPJ', e.cnpj))
    ..write(_t('xNome', e.razaoSocial));
  if (e.nomeFantasia != null && e.nomeFantasia!.isNotEmpty) {
    x.write(_t('xFant', e.nomeFantasia!));
  }
  x
    ..write(_endereco('enderEmit', e.endereco))
    ..write(_t('IE', e.inscricaoEstadual))
    ..write(_t('CRT', '${e.crt}'))
    ..write('</emit>');

  // dest
  final dest = d.destinatario;
  if (dest != null) {
    x.write('<dest>');
    if (dest.cnpj != null) {
      x.write(_t('CNPJ', dest.cnpj!));
    } else if (dest.cpf != null) {
      x.write(_t('CPF', dest.cpf!));
    }
    x.write(_t('xNome', hom ? textoHomologacaoDest : dest.nome));
    if (dest.endereco != null) x.write(_endereco('enderDest', dest.endereco!));
    x.write(_t('indIEDest', '9'));
    if (dest.email != null) x.write(_t('email', dest.email!));
    x.write('</dest>');
  } else if (!nfce) {
    throw ArgumentError('NF-e (modelo 55) exige destinatário');
  }

  // det
  for (var i = 0; i < d.itens.length; i++) {
    final it = d.itens[i];
    if (nfce && it.ipi != null) {
      throw ArgumentError('NFC-e não admite o grupo IPI (item ${i + 1})');
    }
    final desc = hom && i == 0 ? textoHomologacaoItem : it.descricao;
    final q = formatarDecimal(it.quantidade, 4);
    final vu = formatarDecimal(it.valorUnitario, 10);
    final base = it.baseCalculo;
    String? opcional(String tag, double v) => v > 0 ? _t(tag, formatarDecimal(v)) : null;
    x
      ..write('<det nItem="${i + 1}"><prod>')
      ..write(_t('cProd', it.codigo))
      ..write(_t('cEAN', it.gtin))
      ..write(_t('xProd', desc))
      ..write(_t('NCM', it.ncm))
      ..write(it.cest == null ? '' : _t('CEST', it.cest!))
      ..write(it.codigoBeneficio == null ? '' : _t('cBenef', it.codigoBeneficio!))
      ..write(_t('CFOP', it.cfop))
      ..write(_t('uCom', it.unidade))
      ..write(_t('qCom', q))
      ..write(_t('vUnCom', vu))
      ..write(_t('vProd', formatarDecimal(it.valorTotal)))
      ..write(_t('cEANTrib', it.gtin))
      ..write(_t('uTrib', it.unidade))
      ..write(_t('qTrib', q))
      ..write(_t('vUnTrib', vu))
      ..write(opcional('vFrete', it.frete) ?? '')
      ..write(opcional('vSeg', it.seguro) ?? '')
      ..write(opcional('vDesc', it.desconto) ?? '')
      ..write(opcional('vOutro', it.outrasDespesas) ?? '')
      ..write(_t('indTot', '1'))
      ..write('</prod><imposto>')
      ..write(it.valorTributos == null ? '' : _t('vTotTrib', formatarDecimal(it.valorTributos!)))
      ..write('<ICMS>${it.icms.xml(base)}</ICMS>')
      ..write(it.ipi?.xml(base) ?? '')
      ..write('<PIS>${it.pis.xml('PIS', base)}</PIS>')
      ..write('<COFINS>${it.cofins.xml('COFINS', base)}</COFINS>')
      ..write('</imposto></det>');
  }

  // total
  final tot = d.totais;
  String v(double n) => formatarDecimal(n);
  x.write('<total><ICMSTot>');
  for (final (tag, valor) in [
    ('vBC', tot.icms.vBC), ('vICMS', tot.icms.vICMS), ('vICMSDeson', tot.icms.vICMSDeson),
    ('vFCP', tot.icms.vFCP), ('vBCST', tot.icms.vBCST), ('vST', tot.icms.vST),
    ('vFCPST', tot.icms.vFCPST), ('vFCPSTRet', 0.0), ('vProd', tot.vProd), ('vFrete', tot.vFrete),
    ('vSeg', tot.vSeg), ('vDesc', tot.vDesc), ('vII', 0.0), ('vIPI', tot.vIPI), ('vIPIDevol', 0.0),
    ('vPIS', tot.vPIS), ('vCOFINS', tot.vCOFINS), ('vOutro', tot.vOutro), ('vNF', tot.vNF),
  ]) {
    x.write(_t(tag, v(valor)));
  }
  if (tot.vTotTrib > 0) x.write(_t('vTotTrib', v(tot.vTotTrib)));
  x.write('</ICMSTot></total>');

  x.write('<transp>${_t('modFrete', '9')}</transp>');

  // pag
  if (d.pagamentos.isEmpty) throw ArgumentError('Informe ao menos um pagamento');
  x.write('<pag>');
  var pago = 0.0;
  for (final p in d.pagamentos) {
    pago += p.valor;
    if (p.tipo == '99' && (p.descricao ?? '').length < 2) {
      throw ArgumentError('Pagamento tipo 99 exige descrição (xPag)');
    }
    x
      ..write('<detPag>')
      ..write(p.aPrazo ? _t('indPag', '1') : '')
      ..write(_t('tPag', p.tipo))
      ..write(p.descricao == null ? '' : _t('xPag', p.descricao!))
      ..write(_t('vPag', v(p.valor)));
    if (p.exigeCartao || p.cartao != null) {
      final c = p.cartao ?? const Cartao();
      x
        ..write('<card>${_t('tpIntegra', c.integrado ? '1' : '2')}')
        ..write(c.cnpjCredenciadora == null ? '' : _t('CNPJ', c.cnpjCredenciadora!))
        ..write(c.bandeira == null ? '' : _t('tBand', c.bandeira!))
        ..write(c.autorizacao == null ? '' : _t('cAut', c.autorizacao!))
        ..write('</card>');
    }
    x.write('</detPag>');
  }
  final semPagamento = d.pagamentos.every((p) => p.tipo == '90');
  if (!semPagamento && pago + 0.004 < tot.vNF) {
    throw ArgumentError('Pagamentos (${v(pago)}) menores que o total da nota (${v(tot.vNF)})');
  }
  final troco = arredondar(pago - tot.vNF);
  if (!semPagamento && troco > 0) x.write(_t('vTroco', v(troco)));
  x.write('</pag>');

  if (d.informacoesComplementares != null) {
    x.write('<infAdic>${_t('infCpl', d.informacoesComplementares!)}</infAdic>');
  }

  final rt = d.responsavelTecnico;
  if (rt != null) {
    x
      ..write('<infRespTec>')
      ..write(_t('CNPJ', rt.cnpj))
      ..write(_t('xContato', rt.contato))
      ..write(_t('email', rt.email))
      ..write(_t('fone', rt.fone))
      ..write('</infRespTec>');
  }

  x.write('</infNFe></NFe>');
  return NfeMontada(x.toString(), chave);
}

String _t(String tag, String valor) => '<$tag>${escaparXml(valor)}</$tag>';

String _endereco(String tag, Endereco e) {
  final b = StringBuffer('<$tag>')
    ..write(_t('xLgr', e.logradouro))
    ..write(_t('nro', e.numero));
  if (e.complemento != null && e.complemento!.isNotEmpty) b.write(_t('xCpl', e.complemento!));
  b
    ..write(_t('xBairro', e.bairro))
    ..write(_t('cMun', '${e.codigoMunicipio}'))
    ..write(_t('xMun', e.municipio))
    ..write(_t('UF', e.uf.sigla))
    ..write(_t('CEP', e.cep))
    ..write(_t('cPais', '1058'))
    ..write(_t('xPais', 'BRASIL'));
  if (e.fone != null && e.fone!.isNotEmpty) b.write(_t('fone', e.fone!));
  b.write('</$tag>');
  return b.toString();
}
