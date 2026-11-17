import '../enums.dart';

/// Chave de acesso de 44 dígitos (porte de `DFe.Utils/ChaveFiscal.cs`).
class ChaveAcesso {
  ChaveAcesso._(this.valor);

  factory ChaveAcesso.gerar({
    required Uf uf,
    required DateTime dataEmissao,
    required String cnpj,
    required ModeloDocumento modelo,
    required int serie,
    required int numero,
    required TipoEmissao tipoEmissao,
    required int codigoNumerico,
  }) {
    final aamm = '${(dataEmissao.year % 100).toString().padLeft(2, '0')}'
        '${dataEmissao.month.toString().padLeft(2, '0')}';
    final base = '${uf.codigo}$aamm${cnpj.padLeft(14, '0')}${modelo.codigo}'
        '${serie.toString().padLeft(3, '0')}${numero.toString().padLeft(9, '0')}'
        '${tipoEmissao.codigo}${codigoNumerico.toString().padLeft(8, '0')}';
    if (base.length != 43) {
      throw ArgumentError('Chave de acesso com ${base.length} dígitos (esperado 43 + DV)');
    }
    return ChaveAcesso._('$base${calcularDv(base)}');
  }

  /// 44 dígitos.
  final String valor;

  int get digitoVerificador => int.parse(valor[43]);
  String get codigoNumerico => valor.substring(35, 43);

  /// Id do infNFe (`NFe` + chave).
  String get id => 'NFe$valor';

  /// Módulo 11 com pesos 2..9, como no Manual de Orientação do Contribuinte.
  static int calcularDv(String chave43) {
    var soma = 0;
    var peso = 2;
    for (var i = chave43.length - 1; i >= 0; i--) {
      soma += int.parse(chave43[i]) * peso;
      peso = peso == 9 ? 2 : peso + 1;
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  static bool valida(String chave) =>
      RegExp(r'^\d{44}$').hasMatch(chave) &&
      calcularDv(chave.substring(0, 43)) == int.parse(chave[43]);

  @override
  String toString() => valor;
}
