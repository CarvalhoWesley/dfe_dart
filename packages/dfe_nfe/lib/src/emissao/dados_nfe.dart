import '../enums.dart';

/// Modelo de dados simplificado para emissão (venda a consumidor, Simples
/// Nacional). Será substituído pelas classes geradas de `NFe.Classes` na Fase 1.

class Endereco {
  const Endereco({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.codigoMunicipio,
    required this.municipio,
    required this.uf,
    required this.cep,
    this.complemento,
    this.fone,
  });

  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final int codigoMunicipio;
  final String municipio;
  final Uf uf;
  final String cep;
  final String? fone;
}

class Emitente {
  const Emitente({
    required this.cnpj,
    required this.razaoSocial,
    required this.inscricaoEstadual,
    required this.endereco,
    this.nomeFantasia,
    this.crt = 1,
  });

  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String inscricaoEstadual;
  final Endereco endereco;

  /// 1 = Simples Nacional, 2 = SN excesso, 3 = Normal, 4 = MEI.
  /// O exemplo emite ICMS pelo CSOSN 102 (válido para CRT 1 e 4).
  final int crt;
}

class Destinatario {
  const Destinatario({required this.nome, this.cpf, this.cnpj, this.endereco, this.email});

  final String? cpf;
  final String? cnpj;
  final String nome;
  final Endereco? endereco;
  final String? email;
}

class ItemNfe {
  const ItemNfe({
    required this.codigo,
    required this.descricao,
    required this.ncm,
    required this.cfop,
    required this.unidade,
    required this.quantidade,
    required this.valorUnitario,
    this.gtin = 'SEM GTIN',
    this.origem = 0,
    this.csosn = '102',
  });

  final String codigo;
  final String gtin;
  final String descricao;
  final String ncm;
  final String cfop;
  final String unidade;
  final double quantidade;
  final double valorUnitario;
  final int origem;
  final String csosn;

  double get valorTotal => double.parse((quantidade * valorUnitario).toStringAsFixed(2));
}

class Pagamento {
  const Pagamento({required this.tipo, required this.valor});

  /// tPag: 01 dinheiro, 03 crédito, 04 débito, 17 PIX, 90 sem pagamento...
  final String tipo;
  final double valor;
}

/// Responsável técnico (infRespTec) — exigido por algumas UFs.
class ResponsavelTecnico {
  const ResponsavelTecnico({
    required this.cnpj,
    required this.contato,
    required this.email,
    required this.fone,
  });

  final String cnpj;
  final String contato;
  final String email;
  final String fone;
}

class DadosNfe {
  DadosNfe({
    required this.modelo,
    required this.ambiente,
    required this.serie,
    required this.numero,
    required this.emitente,
    required this.itens,
    required this.pagamentos,
    this.destinatario,
    this.naturezaOperacao = 'VENDA',
    this.tipoEmissao = TipoEmissao.normal,
    this.justificativaContingencia,
    DateTime? dataEmissao,
    DateTime? dataContingencia,
    this.informacoesComplementares,
    this.responsavelTecnico,
    this.codigoNumerico,
    this.versaoAplicativo = 'dfe_dart 0.1',
  })  : dataEmissao = dataEmissao ?? DateTime.now(),
        dataContingencia = dataContingencia ??
            (tipoEmissao.contingencia ? (dataEmissao ?? DateTime.now()) : null);

  final ModeloDocumento modelo;
  final Ambiente ambiente;
  final int serie;
  final int numero;
  final Emitente emitente;
  final Destinatario? destinatario;
  final List<ItemNfe> itens;
  final List<Pagamento> pagamentos;
  final String naturezaOperacao;
  final TipoEmissao tipoEmissao;
  final String? justificativaContingencia;
  final DateTime dataEmissao;
  final DateTime? dataContingencia;
  final String? informacoesComplementares;
  final ResponsavelTecnico? responsavelTecnico;

  /// cNF; se nulo, é sorteado.
  final int? codigoNumerico;
  final String versaoAplicativo;

  double get valorProdutos =>
      double.parse(itens.fold<double>(0, (s, i) => s + i.valorTotal).toStringAsFixed(2));
}
