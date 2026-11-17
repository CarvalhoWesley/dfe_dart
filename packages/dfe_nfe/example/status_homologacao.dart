// Consulta o status do serviço em homologação com um certificado A1 real.
//
// Variáveis de ambiente:
//   DFE_PFX_PATH   caminho do .pfx
//   DFE_PFX_SENHA  senha do .pfx
//   DFE_UF         sigla da UF (ex.: SP)
//   DFE_MODELO     55 ou 65 (padrão 65)
//
// dart run example/status_homologacao.dart
import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_transporte_ffi/dfe_transporte_ffi.dart';
import 'package:dfe_nfe/dfe_nfe.dart';

Future<void> main() async {
  final env = Platform.environment;
  final caminho = env['DFE_PFX_PATH'];
  final senha = env['DFE_PFX_SENHA'];
  final uf = env['DFE_UF'];
  if (caminho == null || senha == null || uf == null) {
    stderr.writeln('Defina DFE_PFX_PATH, DFE_PFX_SENHA e DFE_UF.');
    exit(64);
  }

  final cert = CertificadoDigital.dePfx(File(caminho).readAsBytesSync(), senha);
  print('Certificado: ${cert.nomeComum} (válido até ${cert.validoAte.toLocal()})');
  if (cert.vencido) {
    stderr.writeln('ATENÇÃO: certificado vencido; a SEFAZ vai recusar a conexão.');
  }

  final servicos = ServicosNfe(
    ConfiguracaoNfe(
      certificado: cert,
      uf: Uf.porSigla(uf),
      ambiente: Ambiente.homologacao,
      modelo: env['DFE_MODELO'] == '55' ? ModeloDocumento.nfe : ModeloDocumento.nfce,
    ),
    // WinHTTP no Windows, libcurl no Linux.
    transporte: criarTransporteFfi(ConfiguracaoTransporte(certificado: cert)),
  );
  try {
    final r = await servicos.statusServico();
    print('cStat ${r.retorno.cStat}: ${r.retorno.xMotivo}');
    print(r.retornoXml);
    exitCode = r.retorno.emOperacao ? 0 : 1;
  } on ComunicacaoException catch (e) {
    stderr.writeln(e);
    if (e.corpo != null) stderr.writeln(e.corpo);
    exitCode = 2;
  } finally {
    servicos.fechar();
  }
}
