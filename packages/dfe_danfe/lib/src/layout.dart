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
    this.removerAcentos = false,
  });

  /// 48 para papel de 80 mm, 32 para 58 mm (fonte A).
  final int colunas;

  final bool removerAcentos;

  static const papel80mm = OpcoesDanfe();
  static const papel58mm = OpcoesDanfe(colunas: 32);
}

/// Monta o layout do DANFE NFC-e (Manual de Especificações Técnicas do DANFE
/// NFC-e e QR Code).
///
/// Ordem: emitente, título, itens (duas linhas por item), totais e
/// pagamentos, informações complementares, tributos, mensagens de
/// ambiente/contingência, identificação da NFC-e e consulta, consumidor
/// (quando identificado), QR Code e protocolo.
List<ElementoDanfe> montarLayoutNfce(DadosDanfeNfce d, OpcoesDanfe o) {
  final n = o.colunas;
  final r = <ElementoDanfe>[];

  void centro(String s, {bool negrito = false, bool expandido = false}) {
    final largura = expandido ? n ~/ 2 : n;
    for (final l in quebrar(s, largura)) {
      r.add(LinhaDanfe(l, alinhamento: Alinhamento.centro, negrito: negrito, expandido: expandido));
    }
  }

  void esquerda(String s, {bool negrito = false, int recuo = 0}) {
    final linhas = quebrar(s, n);
    for (var i = 0; i < linhas.length; i++) {
      if (i == 0 || recuo == 0) {
        r.add(LinhaDanfe(linhas[i], negrito: negrito));
      } else {
        for (final l in quebrar(linhas.skip(i).join(' '), n - recuo)) {
          r.add(LinhaDanfe('${' ' * recuo}$l', negrito: negrito));
        }
        break;
      }
    }
  }

  void colunas(String esq, String dir, {bool negrito = false}) =>
      r.add(LinhaDanfe(juntar(esq, dir, n), negrito: negrito));

  // Emitente
  centro(d.emitente);
  if (d.nomeFantasia != null) centro(d.nomeFantasia!);
  final endereco = d.enderecoEmitenteLinhas.isNotEmpty
      ? d.enderecoEmitenteLinhas
      : [if (d.enderecoEmitente.isNotEmpty) d.enderecoEmitente];
  for (final l in endereco) {
    centro(l);
  }
  if (d.foneEmitente != null) centro('Telefone: ${d.foneEmitente}');
  centro('CNPJ:${formatarCnpjCpf(d.cnpjEmitente)} IE:${d.ieEmitente}');
  r.add(const SeparadorDanfe());
  centro('Documento Auxiliar da Nota Fiscal de Consumidor Eletrônica');
  r.add(const SeparadorDanfe());

  // Itens
  esquerda('#|COD|DESC|QTD|UN|VL UN R\$|VL TR R\$*|VL ITEM R\$');
  r.add(const SeparadorDanfe());
  for (var i = 0; i < d.itens.length; i++) {
    final it = d.itens[i];
    final seq = (i + 1).toString().padLeft(3, '0');
    esquerda('$seq ${it.codigo} ${it.descricao}', recuo: 4);
    colunas('${formatarDecimal(it.quantidade, 4)} ${it.unidade} X ${formatarDecimal(it.valorUnitario, 3)}',
        formatarValor(it.valorTotal));
  }
  r.add(const SeparadorDanfe());

  // Totais e pagamentos
  colunas('QTDE TOTAL DE ITENS', d.itens.length.toString().padLeft(3, '0'));
  colunas('VALOR TOTAL R\$', formatarValor(d.valorProdutos));
  if (d.desconto > 0) colunas('DESCONTO R\$', formatarValor(d.desconto));
  if (d.acrescimos > 0) colunas('ACRÉSCIMOS R\$', formatarValor(d.acrescimos));
  if (d.desconto > 0 || d.acrescimos > 0) colunas('VALOR A PAGAR R\$', formatarValor(d.valorTotal));
  esquerda('FORMA DE PAGAMENTO');
  for (final p in d.pagamentos) {
    colunas(p.descricao, formatarValor(p.valor));
  }
  if (d.troco > 0) colunas('TROCO R\$', formatarValor(d.troco));
  r.add(const SeparadorDanfe());

  // Informações complementares e tributos (Lei 12.741/2012)
  final complementares = d.informacoesComplementares;
  if (complementares != null) {
    for (final l in complementares.split(RegExp(r'[|;\n]'))) {
      if (l.trim().isNotEmpty) esquerda(l.trim());
    }
  }
  if (d.tributos > 0) {
    esquerda('Tributos Totais Incidentes (Lei Federal 12.741/2012): R\$${formatarValor(d.tributos)}');
  }
  if (complementares != null || d.tributos > 0) r.add(const SeparadorDanfe());

  // Mensagens de ambiente/contingência
  if (d.homologacao) centro('Emitida em Ambiente de Homologação');
  if (d.contingencia) {
    centro('EMITIDA EM CONTINGÊNCIA', negrito: true);
    if (d.pendenteAutorizacao) centro('Pendente de autorização', negrito: true);
  }

  // Identificação da NFC-e e consulta pela chave
  centro('NFCe NR ${d.numero.toString().padLeft(9, '0')} Serie ${d.serie.toString().padLeft(3, '0')} '
      'Emissão ${formatarDataHora(d.dataEmissao)}');
  if (d.urlConsulta.isNotEmpty) centro(d.urlConsulta);
  final chave = formatarChave(d.chave);
  if (chave.length <= n) {
    centro(chave);
  } else {
    // 11 grupos de 4: 6 na primeira linha, 5 na segunda.
    centro(chave.substring(0, 29));
    centro(chave.substring(30));
  }

  // Consumidor (só quando identificado)
  if (d.consumidorDocumento != null) {
    r.add(const SeparadorDanfe());
    final doc = d.consumidorDocumento!;
    final tipo = doc.length == 14 ? 'CNPJ' : doc.length == 11 ? 'CPF' : 'Id. Estrangeiro';
    centro('CONSUMIDOR - $tipo ${formatarCnpjCpf(doc)}');
    if (d.consumidorNome != null) centro(d.consumidorNome!);
  }
  r.add(const SeparadorDanfe());

  // QR Code e protocolo
  if (d.qrCode.isNotEmpty) r.add(QrCodeDanfe(d.qrCode));
  if (d.protocolo != null) {
    centro('Protocolo de Autoriz:${d.protocolo}'
        '${d.dataAutorizacao == null ? '' : ' ${formatarDataHora(d.dataAutorizacao!)}'}');
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

/// Decimal com [casas] casas e vírgula, sem separador de milhar (ex.: "1,0000").
String formatarDecimal(double v, int casas) => v.toStringAsFixed(casas).replaceAll('.', ',');

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
