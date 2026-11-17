@TestOn('windows')
@Tags(['rede'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_transporte_ffi/dfe_transporte_ffi.dart';
import 'package:test/test.dart';

const _fixtures = '../dfe_core/test/fixtures';

CertificadoDigital _cert() => CertificadoDigital.dePfx(
    File('$_fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

void main() {
  // A SEFAZ-SP só pede o certificado do cliente por renegociação TLS, depois
  // da requisição HTTP. O dart:io falha com NO_RENEGOTIATION; o WinHTTP deve
  // chegar até uma resposta HTTP (403, já que o certificado é autoassinado).
  test('SEFAZ-SP: WinHTTP passa pela renegociação TLS', () async {
    final t = TransporteWinHttp(ConfiguracaoTransporte(certificado: _cert()));
    final r = await t.post(
      Uri.parse('https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeStatusServico4.asmx'),
      cabecalhos: {'Content-Type': 'application/soap+xml; charset=utf-8'},
      corpo: Uint8List.fromList(utf8.encode('<x/>')),
      timeout: const Duration(seconds: 30),
    );
    expect(r.status, 403);
  });

  test('dart:io falha na mesma URL (documenta o motivo do transporte nativo)', () async {
    final t = TransporteDartIo(ConfiguracaoTransporte(certificado: _cert()));
    await expectLater(
      t.post(
        Uri.parse('https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeStatusServico4.asmx'),
        cabecalhos: {'Content-Type': 'application/soap+xml; charset=utf-8'},
        corpo: Uint8List.fromList(utf8.encode('<x/>')),
        timeout: const Duration(seconds: 30),
      ),
      throwsA(isA<TransporteException>()
          .having((e) => e.message, 'message', contains('renegociação'))),
    );
    t.fechar();
  });
}
