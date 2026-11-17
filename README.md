# dfe_dart

Biblioteca Dart/Flutter para emissão de documentos fiscais eletrônicos brasileiros
(NF-e e NFC-e), portada do [ZeusFiscal / Hercules.NET](https://github.com/Hercules-NET/ZeusFiscal).

> Validado em homologação na SEFAZ-SP (Windows): NF-e, NF-e em contingência SVC-AN,
> NFC-e e NFC-e em contingência offline autorizadas (cStat 100).

## Pacotes

| Pacote | Conteúdo |
|---|---|
| [`dfe_core`](packages/dfe_core) | Certificado A1 (PKCS#12), C14N, assinatura XMLDSig (idêntica ao `SignedXml` do .NET), cliente SOAP 1.2 |
| [`dfe_nfe`](packages/dfe_nfe) | NF-e/NFC-e 4.00: montagem do XML, chave de acesso, QR Code v2/v3, autorização, `nfeProc`, URLs |
| [`dfe_transporte_ffi`](packages/dfe_transporte_ffi) | TLS mútuo nativo via FFI: WinHTTP/SChannel (Windows) e libcurl (Linux) |
| [`dfe_danfe`](packages/dfe_danfe) | DANFE NFC-e: texto, PDF e bytes ESC/POS a partir do `procNFe` (a impressão fica com o app) |
| [`dfe_flutter`](packages/dfe_flutter) | Plugin Flutter: transporte nativo da plataforma, imagem PNG do DANFE e app de exemplo |

### Por que um transporte nativo?

As SEFAZ pedem o certificado do cliente por **renegociação TLS** depois da requisição
HTTP. O BoringSSL usado pelo `dart:io` recusa renegociação (`NO_RENEGOTIATION`), por isso a
comunicação usa a pilha HTTP do sistema operacional.

## Status por plataforma

| Plataforma | Situação |
|---|---|
| Windows | Validado em homologação (SEFAZ-SP) |
| Android | Compila; renegociação TLS ainda não validada |
| Linux | Implementado, não testado |
| iOS / macOS | Implementado, não compilado |
| Web | Não suportado (navegador não permite certificado de cliente) |

## Uso rápido

```dart
final cert = CertificadoDigital.dePfx(pfxBytes, senha);
final servicos = ServicosNfe(
  ConfiguracaoNfe(certificado: cert, uf: Uf.sp, ambiente: Ambiente.homologacao,
      modelo: ModeloDocumento.nfce),
  transporte: criarTransporteNativo(ConfiguracaoTransporte(certificado: cert)),
);

final doc = EmissorNfe(cert).gerar(dadosDaVenda);   // monta, assina e gera o QR Code
final r = await servicos.autorizar(doc.xmlAssinado, idLote: 1);
if (r.protocolo?.autorizado == true) {
  final procNFe = montarNfeProc(doc.xmlAssinado, r.protocolo!);
}
```

## App de exemplo (Windows)

```bash
cd packages/dfe_flutter/example
flutter run -d windows
```

Emite NF-e/NFC-e em homologação, contingência SVC e NFC-e offline, e grava os XMLs em
`Documentos/dfe_dart/xml`.

## Desenvolvimento

```bash
cd packages/dfe_core && dart test
cd packages/dfe_nfe && dart test
cd packages/dfe_transporte_ffi && dart test   # testes de rede (SEFAZ-SP)
```

Os golden tests de assinatura são gerados por [`tools/golden_assinatura`](tools/golden_assinatura)
(.NET), que reproduz a lógica de assinatura do Zeus. O plano e o histórico de decisões estão em
[`docs/PLANO.md`](docs/PLANO.md).

## Licença

LGPL-2.1, a mesma do projeto de origem (ZeusFiscal). Ver [LICENSE](LICENSE).
