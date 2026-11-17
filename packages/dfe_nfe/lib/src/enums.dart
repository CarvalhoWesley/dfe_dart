/// Ambiente de emissão (tpAmb).
enum Ambiente {
  producao(1),
  homologacao(2);

  const Ambiente(this.codigo);
  final int codigo;
}

/// Modelo do documento (mod).
enum ModeloDocumento {
  nfe(55),
  nfce(65);

  const ModeloDocumento(this.codigo);
  final int codigo;
}

/// Forma de emissão (tpEmis).
enum TipoEmissao {
  normal(1),
  /// Contingência SVC-AN (NF-e).
  svcAn(6),
  /// Contingência SVC-RS (NF-e).
  svcRs(7),
  /// Contingência offline da NFC-e.
  offlineNfce(9);

  const TipoEmissao(this.codigo);
  final int codigo;

  bool get contingencia => this != normal;
}

/// Unidades federativas com o código IBGE (cUF).
enum Uf {
  ro(11), ac(12), am(13), rr(14), pa(15), ap(16), to(17),
  ma(21), pi(22), ce(23), rn(24), pb(25), pe(26), al(27), se(28), ba(29),
  mg(31), es(32), rj(33), sp(35),
  pr(41), sc(42), rs(43),
  ms(50), mt(51), go(52), df(53),
  an(91);

  const Uf(this.codigo);
  final int codigo;

  String get sigla => name.toUpperCase();

  static Uf porSigla(String sigla) =>
      values.firstWhere((u) => u.sigla == sigla.toUpperCase());

  static Uf porCodigo(int codigo) =>
      values.firstWhere((u) => u.codigo == codigo);
}
