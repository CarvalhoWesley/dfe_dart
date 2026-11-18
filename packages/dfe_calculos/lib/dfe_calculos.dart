/// Ferramentas opcionais de cálculo para a NF-e/NFC-e.
///
/// **Não existem no ZeusFiscal.** O `dfe_nfe` emite com os valores
/// informados pelo app (como o Zeus); este pacote ajuda o app a calcular
/// tributos, totais, rateios e troco, aplicar os textos de homologação e
/// conferir regras de negócio. Usar é opcional.
library;

export 'src/calculadora.dart';
export 'src/regras.dart';
