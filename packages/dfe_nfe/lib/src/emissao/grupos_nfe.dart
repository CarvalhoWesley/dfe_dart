// Grupos adicionais da NF-e (ordem dos campos conforme as classes do Zeus):
// NFref, retirada/entrega, autXML, infIntermed, cobr e transp.
import '../util/formatacao.dart';

String _t(String tag, String v) => '<$tag>${escaparXml(v)}</$tag>';
String _o(String tag, String? v) => v == null || v.isEmpty ? '' : _t(tag, v);

/// Documento fiscal referenciado (grupo `NFref`).
sealed class ReferenciaNfe {
  const ReferenciaNfe();

  /// NF-e ou NFC-e referenciada pela chave de acesso (`refNFe`).
  const factory ReferenciaNfe.chave(String chave) = _RefChave;

  /// CT-e referenciado pela chave (`refCTe`).
  const factory ReferenciaNfe.cte(String chave) = _RefCte;

  /// Nota fiscal modelo 1/1A (`refNF`).
  const factory ReferenciaNfe.notaModelo1({
    required int cUF,
    required String aamm,
    required String cnpj,
    String modelo,
    required int serie,
    required int numero,
  }) = _RefNf;

  /// Nota fiscal de produtor rural (`refNFP`).
  const factory ReferenciaNfe.produtorRural({
    required int cUF,
    required String aamm,
    String? cnpj,
    String? cpf,
    required String ie,
    String modelo,
    required int serie,
    required int numero,
  }) = _RefNfp;

  /// Cupom fiscal de ECF (`refECF`).
  const factory ReferenciaNfe.cupomEcf({required String modelo, required int numeroEcf, required int coo}) =
      _RefEcf;

  String xml();
}

class _RefChave extends ReferenciaNfe {
  const _RefChave(this.chave);
  final String chave;
  @override
  String xml() => '<NFref>${_t('refNFe', chave)}</NFref>';
}

class _RefCte extends ReferenciaNfe {
  const _RefCte(this.chave);
  final String chave;
  @override
  String xml() => '<NFref>${_t('refCTe', chave)}</NFref>';
}

class _RefNf extends ReferenciaNfe {
  const _RefNf({
    required this.cUF,
    required this.aamm,
    required this.cnpj,
    this.modelo = '01',
    required this.serie,
    required this.numero,
  });
  final int cUF;
  final String aamm;
  final String cnpj;
  final String modelo;
  final int serie;
  final int numero;
  @override
  String xml() => '<NFref><refNF>${_t('cUF', '$cUF')}${_t('AAMM', aamm)}${_t('CNPJ', cnpj)}'
      '${_t('mod', modelo)}${_t('serie', '$serie')}${_t('nNF', '$numero')}</refNF></NFref>';
}

class _RefNfp extends ReferenciaNfe {
  const _RefNfp({
    required this.cUF,
    required this.aamm,
    this.cnpj,
    this.cpf,
    required this.ie,
    this.modelo = '04',
    required this.serie,
    required this.numero,
  });
  final int cUF;
  final String aamm;
  final String? cnpj;
  final String? cpf;
  final String ie;
  final String modelo;
  final int serie;
  final int numero;
  @override
  String xml() => '<NFref><refNFP>${_t('cUF', '$cUF')}${_t('AAMM', aamm)}'
      '${cnpj != null ? _t('CNPJ', cnpj!) : _t('CPF', cpf ?? '')}${_t('IE', ie)}'
      '${_t('mod', modelo)}${_t('serie', '$serie')}${_t('nNF', '$numero')}</refNFP></NFref>';
}

class _RefEcf extends ReferenciaNfe {
  const _RefEcf({required this.modelo, required this.numeroEcf, required this.coo});
  final String modelo;
  final int numeroEcf;
  final int coo;
  @override
  String xml() => '<NFref><refECF>${_t('mod', modelo)}${_t('nECF', '$numeroEcf'.padLeft(3, '0'))}'
      '${_t('nCOO', '$coo'.padLeft(6, '0'))}</refECF></NFref>';
}

/// Local de retirada ou de entrega (grupos `retirada`/`entrega`).
class LocalNfe {
  const LocalNfe({
    this.cnpj,
    this.cpf,
    this.nome,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.codigoMunicipio,
    required this.municipio,
    required this.uf,
    this.cep,
    this.fone,
    this.email,
    this.ie,
  });

  final String? cnpj;
  final String? cpf;
  final String? nome;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final int codigoMunicipio;
  final String municipio;
  final String uf;
  final String? cep;
  final String? fone;
  final String? email;
  final String? ie;

  String xml(String tag) => '<$tag>${cnpj != null ? _t('CNPJ', cnpj!) : _t('CPF', cpf ?? '')}'
      '${_o('xNome', nome)}${_t('xLgr', logradouro)}${_t('nro', numero)}${_o('xCpl', complemento)}'
      '${_t('xBairro', bairro)}${_t('cMun', '$codigoMunicipio')}${_t('xMun', municipio)}${_t('UF', uf)}'
      '${_o('CEP', cep)}${_t('cPais', '1058')}${_t('xPais', 'BRASIL')}'
      '${_o('fone', fone)}${_o('email', email)}${_o('IE', ie)}</$tag>';
}

/// Intermediador da transação (grupo `infIntermed`).
class Intermediador {
  const Intermediador({required this.cnpj, required this.identificador});
  final String cnpj;

  /// Identificador cadastrado no intermediador (idCadIntTran).
  final String identificador;

  String xml() => '<infIntermed>${_t('CNPJ', cnpj)}${_t('idCadIntTran', identificador)}</infIntermed>';
}

class Fatura {
  const Fatura({this.numero, this.valorOriginal, this.desconto, this.valorLiquido});
  final String? numero;
  final double? valorOriginal;
  final double? desconto;
  final double? valorLiquido;

  String xml() {
    String d(String tag, double? v) => v == null ? '' : _t(tag, formatarDecimal(v));
    return '<fat>${_o('nFat', numero)}${d('vOrig', valorOriginal)}${d('vDesc', desconto)}'
        '${d('vLiq', valorLiquido)}</fat>';
  }
}

class Duplicata {
  const Duplicata({required this.numero, required this.vencimento, required this.valor});
  final String numero;
  final DateTime vencimento;
  final double valor;

  String xml() {
    String p(int v) => v.toString().padLeft(2, '0');
    final venc = '${vencimento.year}-${p(vencimento.month)}-${p(vencimento.day)}';
    return '<dup>${_t('nDup', numero)}${_t('dVenc', venc)}${_t('vDup', formatarDecimal(valor))}</dup>';
  }
}

/// Cobrança (grupo `cobr`).
class Cobranca {
  const Cobranca({this.fatura, this.duplicatas = const []});
  final Fatura? fatura;
  final List<Duplicata> duplicatas;

  String xml() => '<cobr>${fatura?.xml() ?? ''}${duplicatas.map((d) => d.xml()).join()}</cobr>';
}

/// Transportadora (grupo `transporta`).
class Transportadora {
  const Transportadora({this.cnpj, this.cpf, this.nome, this.ie, this.endereco, this.municipio, this.uf});
  final String? cnpj;
  final String? cpf;
  final String? nome;
  final String? ie;
  final String? endereco;
  final String? municipio;
  final String? uf;

  String xml() => '<transporta>${cnpj != null ? _t('CNPJ', cnpj!) : _o('CPF', cpf)}${_o('xNome', nome)}'
      '${_o('IE', ie)}${_o('xEnder', endereco)}${_o('xMun', municipio)}${_o('UF', uf)}</transporta>';
}

/// Veículo (grupo `veicTransp`).
class Veiculo {
  const Veiculo({required this.placa, this.uf, this.rntc});
  final String placa;
  final String? uf;
  final String? rntc;

  String xml() => '<veicTransp>${_t('placa', placa)}${_o('UF', uf)}${_o('RNTC', rntc)}</veicTransp>';
}

/// Volume transportado (grupo `vol`).
class Volume {
  const Volume({this.quantidade, this.especie, this.marca, this.numeracao, this.pesoLiquido, this.pesoBruto});
  final int? quantidade;
  final String? especie;
  final String? marca;
  final String? numeracao;
  final double? pesoLiquido;
  final double? pesoBruto;

  String xml() => '<vol>${quantidade == null ? '' : _t('qVol', '$quantidade')}${_o('esp', especie)}'
      '${_o('marca', marca)}${_o('nVol', numeracao)}'
      '${pesoLiquido == null ? '' : _t('pesoL', formatarDecimal(pesoLiquido!, 3))}'
      '${pesoBruto == null ? '' : _t('pesoB', formatarDecimal(pesoBruto!, 3))}</vol>';
}

/// Transporte (grupo `transp`).
class Transporte {
  const Transporte({this.modalidadeFrete = 9, this.transportadora, this.veiculo, this.volumes = const []});

  /// modFrete: 0 emitente, 1 destinatário, 2 terceiros, 3 próprio emitente,
  /// 4 próprio destinatário, 9 sem frete.
  final int modalidadeFrete;
  final Transportadora? transportadora;
  final Veiculo? veiculo;
  final List<Volume> volumes;

  String xml() => '<transp>${_t('modFrete', '$modalidadeFrete')}${transportadora?.xml() ?? ''}'
      '${veiculo?.xml() ?? ''}${volumes.map((v) => v.xml()).join()}</transp>';
}
