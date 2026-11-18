import 'dart:math';

import '../enums.dart';
import '../status/cons_stat_serv.dart' show nsNfe;
import '../util/chave_acesso.dart';
import '../util/csrt.dart';
import '../util/formatacao.dart';
import 'dados_nfe.dart';

/// Resultado da montagem: XML do `<NFe>` (sem assinatura) e a chave gerada.
class NfeMontada {
  NfeMontada(this.xml, this.chave);
  final String xml;
  final ChaveAcesso chave;
}

/// Monta o XML `<NFe>` 4.00 a partir de [DadosNfe].
///
/// Só serializa os dados informados (anêmico, como o Zeus): não calcula
/// tributos, totais ou troco, não valida regras de negócio e não altera textos.
/// Para isso use o pacote opcional `dfe_calculos`.
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
    ..write(_t('idDest', '${d.destinoOperacao}'))
    ..write(_t('cMunFG', '${d.emitente.endereco.codigoMunicipio}'))
    ..write(_t('tpImp', nfce ? '4' : '1'))
    ..write(_t('tpEmis', '${d.tipoEmissao.codigo}'))
    ..write(_t('cDV', '${chave.digitoVerificador}'))
    ..write(_t('tpAmb', '${d.ambiente.codigo}'))
    ..write(_t('finNFe', '${d.finalidade}'))
    ..write(_t('indFinal', d.consumidorFinal ? '1' : '0'))
    ..write(_t('indPres', '${d.indicadorPresenca}'))
    ..write(_t('procEmi', '0'))
    ..write(_t('verProc', d.versaoAplicativo));
  if (d.tipoEmissao.contingencia) {
    x
      ..write(_t('dhCont', formatarDataHora(d.dataContingencia ?? d.dataEmissao)))
      ..write(_t('xJust', d.justificativaContingencia ?? ''));
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
    x.write(_t('xNome', dest.nome));
    if (dest.endereco != null) x.write(_endereco('enderDest', dest.endereco!));
    x.write(_t('indIEDest', '${dest.indIEDest}'));
    if (dest.email != null) x.write(_t('email', dest.email!));
    x.write('</dest>');
  }

  // det
  for (var i = 0; i < d.itens.length; i++) {
    final it = d.itens[i];
    final q = formatarDecimal(it.quantidade, 4);
    final vu = formatarDecimal(it.valorUnitario, 10);
    String? opcional(String tag, double v) => v > 0 ? _t(tag, formatarDecimal(v)) : null;
    x
      ..write('<det nItem="${i + 1}"><prod>')
      ..write(_t('cProd', it.codigo))
      ..write(_t('cEAN', it.gtin))
      ..write(_t('xProd', it.descricao))
      ..write(_t('NCM', it.ncm))
      ..write(it.cest == null ? '' : _t('CEST', it.cest!))
      ..write(it.codigoBeneficio == null ? '' : _t('cBenef', it.codigoBeneficio!))
      ..write(_t('CFOP', it.cfop))
      ..write(_t('uCom', it.unidade))
      ..write(_t('qCom', q))
      ..write(_t('vUnCom', vu))
      ..write(_t('vProd', formatarDecimal(it.valorTotal)))
      ..write(_t('cEANTrib', it.gtinTributavel ?? it.gtin))
      ..write(_t('uTrib', it.unidadeTributavel ?? it.unidade))
      ..write(_t('qTrib', it.quantidadeTributavel == null ? q : formatarDecimal(it.quantidadeTributavel!, 4)))
      ..write(_t('vUnTrib',
          it.valorUnitarioTributavel == null ? vu : formatarDecimal(it.valorUnitarioTributavel!, 10)))
      ..write(opcional('vFrete', it.frete) ?? '')
      ..write(opcional('vSeg', it.seguro) ?? '')
      ..write(opcional('vDesc', it.desconto) ?? '')
      ..write(opcional('vOutro', it.outrasDespesas) ?? '')
      ..write(_t('indTot', it.compoeTotal ? '1' : '0'))
      ..write('</prod>')
      ..write(it.imposto.xml(e.crt))
      ..write('</det>');
  }

  // total
  x
    ..write(d.total.xml())
    ..write('<transp>${_t('modFrete', '${d.modalidadeFrete}')}</transp>');

  // pag
  x.write('<pag>');
  for (final p in d.pagamentos) {
    x
      ..write('<detPag>')
      ..write(p.aPrazo ? _t('indPag', '1') : '')
      ..write(_t('tPag', p.tipo))
      ..write(p.descricao == null ? '' : _t('xPag', p.descricao!))
      ..write(_t('vPag', formatarDecimal(p.valor)));
    final c = p.cartao;
    if (c != null) {
      x
        ..write('<card>${_t('tpIntegra', c.integrado ? '1' : '2')}')
        ..write(c.cnpjCredenciadora == null ? '' : _t('CNPJ', c.cnpjCredenciadora!))
        ..write(c.bandeira == null ? '' : _t('tBand', c.bandeira!))
        ..write(c.autorizacao == null ? '' : _t('cAut', c.autorizacao!))
        ..write('</card>');
    }
    x.write('</detPag>');
  }
  if (d.troco != null && d.troco! > 0) x.write(_t('vTroco', formatarDecimal(d.troco!)));
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
      ..write(_t('fone', rt.fone));
    if (rt.idCsrt != null && rt.csrt != null) {
      x
        ..write(_t('idCSRT', rt.idCsrt!.toString().padLeft(2, '0')))
        ..write(_t('hashCSRT', hashCsrt(rt.csrt!, chave.valor)));
    }
    x.write('</infRespTec>');
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
