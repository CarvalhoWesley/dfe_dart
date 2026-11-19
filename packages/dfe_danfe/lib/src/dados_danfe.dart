import 'package:xml/xml.dart';

/// Dados da NFC-e necessários ao DANFE, lidos do `nfeProc` (ou do `<NFe>`
/// ainda sem protocolo, no caso de contingência offline).
class DadosDanfeNfce {
  DadosDanfeNfce._({
    required this.emitente,
    required this.cnpjEmitente,
    required this.ieEmitente,
    required this.enderecoEmitente,
    this.enderecoEmitenteLinhas = const [],
    this.foneEmitente,
    required this.itens,
    required this.valorProdutos,
    required this.desconto,
    required this.acrescimos,
    required this.valorTotal,
    required this.pagamentos,
    required this.troco,
    required this.tributos,
    required this.chave,
    required this.urlConsulta,
    required this.qrCode,
    required this.numero,
    required this.serie,
    required this.dataEmissao,
    required this.homologacao,
    required this.contingencia,
    this.consumidorDocumento,
    this.consumidorNome,
    this.protocolo,
    this.dataAutorizacao,
    this.informacoesComplementares,
    this.nomeFantasia,
  });

  factory DadosDanfeNfce.deXml(String xml) {
    final doc = XmlDocument.parse(xml);
    final inf = doc.findAllElements('infNFe').firstOrNull ??
        (throw ArgumentError('XML sem infNFe'));
    final ide = inf.getElement('ide')!;
    final emit = inf.getElement('emit')!;
    final ender = emit.getElement('enderEmit');
    final tot = inf.getElement('total')!.getElement('ICMSTot')!;
    final supl = doc.findAllElements('infNFeSupl').firstOrNull;
    final prot = doc.findAllElements('infProt').firstOrNull;
    final dest = inf.getElement('dest');

    String t(XmlElement? e, String n) => e?.getElement(n)?.innerText ?? '';
    double d(XmlElement? e, String n) => double.tryParse(t(e, n)) ?? 0;

    final mod = t(ide, 'mod');
    if (mod != '65') {
      throw ArgumentError('DANFE NFC-e exige modelo 65 (recebido: $mod)');
    }

    final endereco = ender == null
        ? ''
        : [
            [t(ender, 'xLgr'), t(ender, 'nro'), t(ender, 'xCpl')].where((s) => s.isNotEmpty).join(', '),
            t(ender, 'xBairro'),
            '${t(ender, 'xMun')} - ${t(ender, 'UF')}',
          ].where((s) => s.trim().isNotEmpty).join(', ');

    final cep = t(ender, 'CEP');
    final linhas = ender == null
        ? const <String>[]
        : [
            [
              [t(ender, 'xLgr'), t(ender, 'nro'), t(ender, 'xCpl')].where((s) => s.isNotEmpty).join(', '),
              if (cep.length == 8) '${cep.substring(0, 5)}-${cep.substring(5)}',
            ].join(' - '),
            [t(ender, 'xBairro'), '${t(ender, 'xMun')}/${t(ender, 'UF')}']
                .where((s) => s.isNotEmpty).join(' - '),
          ];
    final fone = t(ender, 'fone');

    final itens = inf.findElements('det').map((det) {
      final p = det.getElement('prod')!;
      return ItemDanfe(
        codigo: t(p, 'cProd'),
        descricao: t(p, 'xProd'),
        quantidade: d(p, 'qCom'),
        unidade: t(p, 'uCom'),
        valorUnitario: d(p, 'vUnCom'),
        valorTotal: d(p, 'vProd'),
      );
    }).toList();

    final pag = inf.getElement('pag');
    final pagamentos = (pag?.findElements('detPag') ?? const <XmlElement>[])
        .map((p) => PagamentoDanfe(t(p, 'tPag'), d(p, 'vPag')))
        .toList();

    final cStat = t(prot, 'cStat');
    return DadosDanfeNfce._(
      emitente: t(emit, 'xNome'),
      nomeFantasia: t(emit, 'xFant').isEmpty ? null : t(emit, 'xFant'),
      cnpjEmitente: t(emit, 'CNPJ').isNotEmpty ? t(emit, 'CNPJ') : t(emit, 'CPF'),
      ieEmitente: t(emit, 'IE'),
      enderecoEmitente: endereco,
      enderecoEmitenteLinhas: linhas,
      foneEmitente: fone.isEmpty ? null : _formatarFone(fone),
      itens: itens,
      valorProdutos: d(tot, 'vProd'),
      desconto: d(tot, 'vDesc'),
      acrescimos: d(tot, 'vFrete') + d(tot, 'vSeg') + d(tot, 'vOutro'),
      valorTotal: d(tot, 'vNF'),
      pagamentos: pagamentos,
      troco: d(pag, 'vTroco'),
      tributos: d(tot, 'vTotTrib'),
      chave: (inf.getAttribute('Id') ?? '').replaceFirst('NFe', ''),
      urlConsulta: t(supl, 'urlChave'),
      qrCode: t(supl, 'qrCode'),
      numero: int.tryParse(t(ide, 'nNF')) ?? 0,
      serie: int.tryParse(t(ide, 'serie')) ?? 0,
      dataEmissao: _horaLocal(t(ide, 'dhEmi')),
      homologacao: t(ide, 'tpAmb') == '2',
      contingencia: t(ide, 'tpEmis') == '9',
      consumidorDocumento: dest == null
          ? null
          : (t(dest, 'CPF').isNotEmpty
              ? t(dest, 'CPF')
              : t(dest, 'CNPJ').isNotEmpty
                  ? t(dest, 'CNPJ')
                  : t(dest, 'idEstrangeiro')),
      consumidorNome: dest == null || t(dest, 'xNome').isEmpty ? null : t(dest, 'xNome'),
      protocolo: cStat == '100' || cStat == '150' ? t(prot, 'nProt') : null,
      dataAutorizacao: prot == null || t(prot, 'dhRecbto').isEmpty
          ? null
          : _horaLocal(t(prot, 'dhRecbto')),
      informacoesComplementares: t(inf.getElement('infAdic'), 'infCpl').isEmpty
          ? null
          : t(inf.getElement('infAdic'), 'infCpl'),
    );
  }

  final String emitente;
  final String? nomeFantasia;
  final String cnpjEmitente;
  final String ieEmitente;
  final String enderecoEmitente;

  /// Endereço em linhas: "logradouro, número - CEP" e "bairro - município/UF".
  final List<String> enderecoEmitenteLinhas;

  /// Telefone do emitente formatado, ex.: "(16)3847-1885".
  final String? foneEmitente;
  final List<ItemDanfe> itens;
  final double valorProdutos;
  final double desconto;
  final double acrescimos;
  final double valorTotal;
  final List<PagamentoDanfe> pagamentos;
  final double troco;
  final double tributos;
  final String chave;
  final String urlConsulta;
  final String qrCode;
  final int numero;
  final int serie;
  final DateTime dataEmissao;
  final bool homologacao;
  final bool contingencia;
  final String? consumidorDocumento;
  final String? consumidorNome;
  final String? protocolo;
  final DateTime? dataAutorizacao;
  final String? informacoesComplementares;

  /// Emitida em contingência e ainda sem protocolo de autorização.
  bool get pendenteAutorizacao => protocolo == null;
}

class ItemDanfe {
  const ItemDanfe({
    required this.codigo,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  final String codigo;
  final String descricao;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final double valorTotal;
}

class PagamentoDanfe {
  const PagamentoDanfe(this.tipo, this.valor);
  final String tipo;
  final double valor;

  String get descricao => switch (tipo) {
        '01' => 'Dinheiro',
        '02' => 'Cheque',
        '03' => 'Cartão de Crédito',
        '04' => 'Cartão de Débito',
        '05' => 'Crédito Loja',
        '10' => 'Vale Alimentação',
        '11' => 'Vale Refeição',
        '12' => 'Vale Presente',
        '13' => 'Vale Combustível',
        '15' => 'Boleto Bancário',
        '16' => 'Depósito Bancário',
        '17' => 'PIX',
        '18' => 'Transferência',
        '19' => 'Fidelidade/Cashback',
        '20' => 'PIX Estático',
        '90' => 'Sem pagamento',
        _ => 'Outros',
      };
}

String _formatarFone(String f) => switch (f.length) {
      10 => '(${f.substring(0, 2)})${f.substring(2, 6)}-${f.substring(6)}',
      11 => '(${f.substring(0, 2)})${f.substring(2, 7)}-${f.substring(7)}',
      _ => f,
    };

/// Data/hora como escrita no XML (hora local do emissor), ignorando o fuso.
DateTime _horaLocal(String s) => DateTime.parse(s.length >= 19 ? s.substring(0, 19) : s);
