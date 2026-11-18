// Grava os XMLs de referência (montagem sem assinatura) com a API legada.
// Uso (uma vez, antes da refatoração): dart run test/regressao/gravar_esperado.dart
import 'dart:io';

import 'package:dfe_nfe/dfe_nfe.dart';

import 'cenarios_legado.dart';

void main() {
  final dir = Directory('test/regressao/esperado')..createSync(recursive: true);
  for (final MapEntry(key: nome, value: dados) in cenariosLegado().entries) {
    File('${dir.path}/$nome.xml').writeAsStringSync(montarNfe(dados).xml);
    stdout.writeln('gravado: $nome');
  }
}
