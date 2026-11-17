import 'dados_danfe.dart';

enum Alinhamento { esquerda, centro, direita }

/// Elemento do layout do DANFE, independente do formato de saída.
sealed class ElementoDanfe {
  const ElementoDanfe();
}

/// Linha de texto já cabendo na largura (metade da largura quando [expandido]).
class LinhaDanfe extends ElementoDanfe {
  const LinhaDanfe(this.texto,
      {this.alinhamento = Alinhamento.esquerda, this.negrito = false, this.expandido = false});
  final String texto;
  final Alinhamento alinhamento;
  final bool negrito;

  /// Fonte em largura e altura duplas.
  final bool expandido;
}

class SeparadorDanfe extends ElementoDanfe {
  const SeparadorDanfe();
}

class QrCodeDanfe extends ElementoDanfe {
  const QrCodeDanfe(this.conteudo);
  final String conteudo;
}

/// Opções de layout do DANFE NFC-e.
class OpcoesDanfe {
  const OpcoesDanfe({
    this.colunas = 48,
    this.itemEmDuasLinhas = false,
    this.removerAcentos = false,
  });

  /// 48 para papel de 80 mm, 32 para 58 mm (fonte A).
  final int colunas;

  /// Item em duas linhas (descrição completa + valores) em vez de uma.
  final bool itemEmDuasLinhas;

  final bool removerAcentos;

  static const papel80mm = OpcoesDanfe();
  static const papel58mm = OpcoesDanfe(colunas: 32, itemEmDuasLinhas: true);
}

/// Monta o layout do DANFE NFC-e (Manual de Especificações Técnicas do DANFE
/// NFC-e e QR Code), divisões I a IX.
List<ElementoDanfe> montarLayoutNfce(DadosDanfeNfce d, OpcoesDanfe o) {
  final n = o.colunas;
  final r = <ElementoDanfe>[];

  void centro(String s, {bool negrito = false, bool expandido = false}) {
    final largura = expandido ? n ~/ 2 : n;
    for (final l in quebrar(s, largura)) {
      r.add(LinhaDanfe(l, alinhamento: Alinhamento.centro, negrito: negrito, expandido: expandido));
    }
  }

  void esquerda(String s, {bool negrito = false}) {
    for (final l in quebrar(s, n)) {
      r.add(LinhaDanfe(l, negrito: negrito));
    }
  }

  void colunas(String esq, String dir, {bool negrito = false}) =>
      r.add(LinhaDanfe(juntar(esq, dir, n), negrito: negrito));

  // I - Emitente
  centro(d.nomeFantasia ?? d.emitente, negrito: true);
  if (d.nomeFantasia != null) centro(d.emitente);
  centro('CNPJ: ${formatarCnpjCpf(d.cnpjEmitente)}  IE: ${d.ieEmitente}');
  if (d.enderecoEmitente.isNotEmpty) centro(d.enderecoEmitente);
  r.add(const SeparadorDanfe());
  centro('Documento Auxiliar da Nota Fiscal de Consumidor Eletrônica', negrito: true);
  r.add(const SeparadorDanfe());

  // II - Itens
  if (o.itemEmDuasLinhas) {
    colunas('#  Código Descrição', '', negrito: true);
    colunas('Qtde UN x Vl Unit', 'Vl Total', negrito: true);
  } else {
    colunas('Código Descrição', _colunasValores('Qtde', 'UN', 'Vl Unit', 'Vl Total'),
        negrito: true);
  }
  for (var i = 0; i < d.itens.length; i++) {
    final it = d.itens[i];
    final qtd = formatarQuantidade(it.quantidade);
    final vu = formatarValor(it.valorUnitario);
    final vt = formatarValor(it.valorTotal);
    final seq = (i + 1).toString().padLeft(3, '0');
    if (o.itemEmDuasLinhas) {
      esquerda('$seq ${it.codigo} ${it.descricao}');
      colunas('   $qtd ${it.unidade} x $vu', vt);
    } else {
      final dir = _colunasValores(qtd, it.unidade, vu, vt);
      final esqMax = n - dir.length - 1;
      final esq = '${it.codigo} ${it.descricao}';
      colunas(esq.length > esqMax ? esq.substring(0, esqMax) : esq, dir);
    }
  }
  r.add(const SeparadorDanfe());

  // III - Totais e pagamentos
  colunas('Qtde. total de itens', '${d.itens.length}');
  colunas('Valor total R\$', formatarValor(d.valorProdutos));
  if (d.desconto > 0) colunas('Desconto R\$', formatarValor(d.desconto));
  if (d.acrescimos > 0) colunas('Acréscimos R\$', formatarValor(d.acrescimos));
  colunas('Valor a Pagar R\$', formatarValor(d.valorTotal), negrito: true);
  colunas('FORMA PAGAMENTO', 'VALOR PAGO R\$', negrito: true);
  for (final p in d.pagamentos) {
    colunas(p.descricao, formatarValor(p.valor));
  }
  if (d.troco > 0) colunas('Troco R\$', formatarValor(d.troco));
  r.add(const SeparadorDanfe());

  // IV - Tributos (Lei 12.741/2012)
  if (d.tributos > 0) {
    esquerda('Informação dos Tributos Totais Incidentes (Lei Federal 12.741/2012) '
        'R\$ ${formatarValor(d.tributos)}');
    r.add(const SeparadorDanfe());
  }

  // Mensagens de ambiente/contingência (área de mensagem fiscal)
  if (d.homologacao) {
    centro('EMITIDA EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL', negrito: true);
  }
  if (d.contingencia) {
    centro('EMITIDA EM CONTINGÊNCIA', negrito: true);
    if (d.pendenteAutorizacao) centro('Pendente de autorização', negrito: true);
  }

  // V - Consulta pela chave
  centro('Consulte pela Chave de Acesso em');
  centro(d.urlConsulta);
  final chave = formatarChave(d.chave);
  if (chave.length <= n) {
    centro(chave);
  } else {
    // 11 grupos de 4: 6 na primeira linha, 5 na segunda.
    centro(chave.substring(0, 29));
    centro(chave.substring(30));
  }
  r.add(const SeparadorDanfe());

  // VI - Consumidor
  if (d.consumidorDocumento == null) {
    centro('CONSUMIDOR NÃO IDENTIFICADO', negrito: true);
  } else {
    centro('CONSUMIDOR - ${d.consumidorDocumento!.length == 14 ? 'CNPJ' : d.consumidorDocumento!.length == 11 ? 'CPF' : 'Id. Estrangeiro'} '
        '${formatarCnpjCpf(d.consumidorDocumento!)}', negrito: true);
    if (d.consumidorNome != null) centro(d.consumidorNome!);
  }
  r.add(const SeparadorDanfe());

  // VII - Identificação da NFC-e e protocolo
  centro('NFC-e nº ${d.numero.toString().padLeft(9, '0')} Série ${d.serie.toString().padLeft(3, '0')} '
      '${formatarDataHora(d.dataEmissao)}', negrito: true);
  if (d.protocolo != null) {
    centro('Protocolo de autorização: ${d.protocolo}');
    if (d.dataAutorizacao != null) centro('Data de autorização: ${formatarDataHora(d.dataAutorizacao!)}');
  }

  // VIII - QR Code
  if (d.qrCode.isNotEmpty) r.add(QrCodeDanfe(d.qrCode));

  // IX - Informações complementares
  if (d.informacoesComplementares != null) {
    r.add(const SeparadorDanfe());
    esquerda(d.informacoesComplementares!);
  }

  if (!o.removerAcentos) return r;
  return [
    for (final e in r)
      e is LinhaDanfe
          ? LinhaDanfe(removerAcentos(e.texto),
              alinhamento: e.alinhamento, negrito: e.negrito, expandido: e.expandido)
          : e,
  ];
}

// --- Formatação ---------------------------------------------------------------

/// Colunas de valores do item em uma linha: Qtde(6) UN(3) Vl Unit(8) Vl Total(9).
String _colunasValores(String qtd, String un, String vu, String vt) {
  String corta(String s, int n) => s.length > n ? s.substring(0, n) : s;
  return '${corta(qtd, 6).padLeft(6)} ${corta(un, 3).padRight(3)}'
      '${corta(vu, 8).padLeft(8)}${corta(vt, 9).padLeft(9)}';
}

String formatarValor(double v) {
  final s = v.toStringAsFixed(2);
  final partes = s.split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '$inteiro,${partes[1]}';
}

String formatarQuantidade(double q) {
  if (q == q.roundToDouble()) return q.toStringAsFixed(0);
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');
}

String formatarDataHora(DateTime d) {
  // Mantém o horário local informado no XML (sem converter o fuso).
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
}

String formatarCnpjCpf(String s) {
  if (s.length == 14) {
    return '${s.substring(0, 2)}.${s.substring(2, 5)}.${s.substring(5, 8)}/${s.substring(8, 12)}-${s.substring(12)}';
  }
  if (s.length == 11) {
    return '${s.substring(0, 3)}.${s.substring(3, 6)}.${s.substring(6, 9)}-${s.substring(9)}';
  }
  return s;
}

String formatarChave(String c) =>
    [for (var i = 0; i < c.length; i += 4) c.substring(i, i + 4 > c.length ? c.length : i + 4)].join(' ');

/// Esquerda e direita na mesma linha; se não couber, a esquerda é cortada.
String juntar(String esq, String dir, int n) {
  final espaco = n - dir.length;
  if (espaco <= 1) return dir.length > n ? dir.substring(0, n) : dir;
  final e = esq.length >= espaco ? esq.substring(0, espaco - 1) : esq;
  return '$e${' ' * (n - e.length - dir.length)}$dir';
}

/// Quebra o texto em linhas de até [n] caracteres, preferindo espaços.
List<String> quebrar(String s, int n) {
  final linhas = <String>[];
  var resto = s.trim();
  while (resto.length > n) {
    var corte = resto.lastIndexOf(' ', n);
    if (corte <= 0) corte = n;
    linhas.add(resto.substring(0, corte).trimRight());
    resto = resto.substring(corte).trimLeft();
  }
  if (resto.isNotEmpty || linhas.isEmpty) linhas.add(resto);
  return linhas;
}

const _acentos = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ç': 'C', 'Ñ': 'N', 'º': 'o', 'ª': 'a',
};

String removerAcentos(String s) => s.split('').map((c) => _acentos[c] ?? c).join();
