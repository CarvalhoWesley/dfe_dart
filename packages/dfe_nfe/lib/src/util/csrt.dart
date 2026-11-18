import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Hash do CSRT (Código de Segurança do Responsável Técnico) para o grupo
/// `infRespTec`: base64(SHA-1(CSRT + chave de acesso)), conforme a NT 2018.005.
///
/// Porte de `GerarHashCSRT.HashCSRT(csrt, chave)` do Zeus. Observação: a
/// sobrecarga do Zeus que recebe a NF-e usa `infNFe.Id.Substring(0, 3)` ("NFe")
/// no lugar da chave; aqui sempre se usa a chave de 44 dígitos.
String hashCsrt(String csrt, String chave) {
  final dados = Uint8List.fromList(utf8.encode('$csrt$chave'));
  return base64.encode(SHA1Digest().process(dados));
}
