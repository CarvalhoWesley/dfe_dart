import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';

const _chave = '35261112345678000195550010000004561123456780';

/// Transporte que devolve respostas prontas e guarda os envios.
class _Falso implements TransporteSoap {
  _Falso(this.respostas);
  final List<String> respostas;
  final enviados = <String>[];

  @override
  Future<RespostaHttp> post(Uri url,
      {required Map<String, String> cabecalhos, required Uint8List corpo, required Duration timeout}) async {
    enviados.add(utf8.decode(corpo));
    return RespostaHttp(200,
        '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>'
        '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeRecepcaoEvento4">'
        '${respostas.removeAt(0)}</nfeResultMsg></soap:Body></soap:Envelope>');
  }

  @override
  void fechar() {}
}

String _ret(int cStat, String dhReg) => '<retEnvEvento xmlns="$nsNfe" versao="1.00"><idLote>1</idLote>'
    '<tpAmb>2</tpAmb><cOrgao>35</cOrgao><cStat>128</cStat><xMotivo>Lote processado</xMotivo>'
    '<retEvento versao="1.00"><infEvento><tpAmb>2</tpAmb><cOrgao>35</cOrgao><cStat>$cStat</cStat>'
    '<xMotivo>x</xMotivo><chNFe>$_chave</chNFe><tpEvento>110110</tpEvento><nSeqEvento>1</nSeqEvento>'
    '${cStat == 135 ? '<nProt>135260000000777</nProt>' : ''}<dhRegEvento>$dhReg</dhRegEvento>'
    '</infEvento></retEvento></retEnvEvento>';

String? _dh(String xml) => RegExp(r'<dhEvento>([^<]+)</dhEvento>').firstMatch(xml)?.group(1);

void main() {
  final cert = CertificadoDigital.dePfx(
      File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');
  ServicosNfe servicos(_Falso t) => ServicosNfe(
        ConfiguracaoNfe(
            certificado: cert, uf: Uf.sp, ambiente: Ambiente.homologacao, modelo: ModeloDocumento.nfe),
        transporte: t,
      );
  String horario(DateTime d) => formatarDataHora(d);

  test('relógio da SEFAZ atrasado: reenvia com o horário de registro − 2 s', () async {
    final registro = DateTime.now().subtract(const Duration(seconds: 10));
    final t = _Falso([_ret(999, horario(registro)), _ret(135, horario(DateTime.now()))]);
    final r = await servicos(t).cartaCorrecao(
        chave: _chave, correcao: 'CORRECAO DE TESTE DO REENVIO', sequencia: 1, idLote: 1);

    expect(t.enviados, hasLength(2));
    final segundo = DateTime.parse(_dh(t.enviados[1])!);
    final esperado = registro.subtract(const Duration(seconds: 2));
    expect(segundo.difference(esperado).inSeconds.abs(), lessThanOrEqualTo(1));
    expect(r.retEvento!.registrado, isTrue);
    expect(r.procEventoXml, isNotNull);
    expect(verificarAssinatura(r.evento.xml).valido, isTrue);
  });

  test('rejeição com horário coerente não reenvia', () async {
    final t = _Falso([_ret(999, horario(DateTime.now().add(const Duration(seconds: 30))))]);
    final r = await servicos(t).cartaCorrecao(
        chave: _chave, correcao: 'CORRECAO DE TESTE DO REENVIO', sequencia: 1, idLote: 1);
    expect(t.enviados, hasLength(1));
    expect(r.retEvento!.cStat, 999);
  });
}
