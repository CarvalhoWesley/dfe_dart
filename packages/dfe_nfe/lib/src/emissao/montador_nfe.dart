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
    final desc = hom && i == 0 ? textoHomologacaoItem : it.descricao;
    final q = formatarDecimal(it.quantidade, 4);
    final vu = formatarDecimal(it.valorUnitario, 10);
    x
      ..write('<det nItem="${i + 1}"><prod>')
      ..write(_t('cProd', it.codigo))
      ..write(_t('cEAN', it.gtin))
      ..write(_t('xProd', desc))
      ..write(_t('NCM', it.ncm))
      ..write(_t('CFOP', it.cfop))
      ..write(_t('uCom', it.unidade))
      ..write(_t('qCom', q))
      ..write(_t('vUnCom', vu))
      ..write(_t('vProd', formatarDecimal(it.valorTotal)))
      ..write(_t('cEANTrib', it.gtin))
      ..write(_t('uTrib', it.unidade))
      ..write(_t('qTrib', q))
      ..write(_t('vUnTrib', vu))
      ..write(_t('indTot', '1'))
      ..write('</prod><imposto>')
      ..write('<ICMS><ICMSSN${it.csosn}>')
      ..write(_t('orig', '${it.origem}'))
      ..write(_t('CSOSN', it.csosn))
      ..write('</ICMSSN${it.csosn}></ICMS>')
      ..write('<PIS><PISNT>${_t('CST', '07')}</PISNT></PIS>')
      ..write('<COFINS><COFINSNT>${_t('CST', '07')}</COFINSNT></COFINS>')
      ..write('</imposto></det>');
  }

  // total
  final vProd = formatarDecimal(d.valorProdutos);
  const z = '0.00';
  x.write('<total><ICMSTot>');
  for (final (tag, v) in [
    ('vBC', z), ('vICMS', z), ('vICMSDeson', z), ('vFCP', z), ('vBCST', z),
    ('vST', z), ('vFCPST', z), ('vFCPSTRet', z), ('vProd', vProd), ('vFrete', z),
    ('vSeg', z), ('vDesc', z), ('vII', z), ('vIPI', z), ('vIPIDevol', z),
    ('vPIS', z), ('vCOFINS', z), ('vOutro', z), ('vNF', vProd),
  ]) {
    x.write(_t(tag, v));
  }
  x.write('</ICMSTot></total>');

  x.write('<transp>${_t('modFrete', '9')}</transp>');

  // pag
  x.write('<pag>');
  var pago = 0.0;
  for (final p in d.pagamentos) {
    pago += p.valor;
    x.write('<detPag>${_t('tPag', p.tipo)}${_t('vPag', formatarDecimal(p.valor))}</detPag>');
  }
  final troco = pago - d.valorProdutos;
  if (troco > 0.004) x.write(_t('vTroco', formatarDecimal(troco)));
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
