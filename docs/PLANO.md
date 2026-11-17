# dfe_dart — Plano da v1 (NFe + NFC-e)

Porte para Dart/Flutter do [ZeusFiscal](https://github.com/Hercules-NET/ZeusFiscal) (.NET), referência local:
`D:\Pessoas\Outros\Projetos\zeus_fiscal`.

## Decisões

| Tema | Decisão |
|---|---|
| Escopo v1 | NF-e (mod. 55) e NFC-e (mod. 65), layout 4.00 |
| Modelos | Gerados por script a partir de `NFe.Classes` / `DFe.Classes` (C#) |
| Certificado | Somente A1 (.pfx). A3 fora da v1 |
| Plataformas | Android, iOS, Windows, Linux, macOS. **Sem Flutter Web** (TLS mútuo indisponível no navegador) |
| Impressão | DANFE NF-e A4 em PDF; DANFE NFC-e em PDF (80mm) e ESC/POS |
| Licença | LGPL (obra derivada do Zeus) |
| API | Assíncrona (`Future`), configuração imutável injetada, retornos `sealed` |

## Estrutura (monorepo com melos)

```
dfe_dart/
  packages/
    dfe_core/     # XML, C14N, XMLDSig, PKCS#12, SOAP 1.2, chave de acesso, enums comuns
    nfe/          # modelos gerados, URLs por UF, ServicosNFe, QR Code NFC-e, CSRT
    nfe_danfe/    # DANFE NF-e A4 (pdf), NFC-e 80mm (pdf + ESC/POS)
  tools/
    gerador/      # C# (NFe.Classes) -> Dart
  docs/
```

Dependências previstas: `xml`, `pointycastle`, `asn1lib`, `crypto`, `http` (via `dart:io HttpClient` c/ `SecurityContext`), `pdf`, `printing`, `barcode`, `esc_pos_utils_plus`, `intl`.

## Mapeamento Zeus → Dart

| Zeus (.NET) | dfe_dart |
|---|---|
| `DFe.Utils/Assinatura/*`, `NFe.Utils/Assinatura/Assinador.cs` | `dfe_core/lib/src/assinatura/` (C14N + XMLDSig) |
| `DFe.Utils/Assinatura/CertificadoDigital.cs` | `dfe_core/lib/src/certificado/` (PKCS#12) |
| `DFe.Wsdl/*`, `NFe.Wsdl/*` | `dfe_core/lib/src/soap/` + clientes por serviço em `nfe` |
| `DFe.Utils/ChaveFiscal.cs` | `dfe_core/lib/src/chave_fiscal.dart` |
| `NFe.Utils/Enderecos/*` | `nfe/lib/src/enderecos/` (tabela UF × ambiente × serviço × modelo) |
| `NFe.Classes/**` | `nfe/lib/src/classes/**` (gerado) |
| `NFe.Utils/InformacoesSuplementares/ExtinfNFeSupl.cs` | `nfe/lib/src/qrcode/` |
| `NFe.Utils/InfRespTec/GerarHashCSRT.cs` | `nfe/lib/src/csrt.dart` |
| `NFe.Servicos/ServicosNFe.cs` | `nfe/lib/src/servicos_nfe.dart` |
| `NFe.Danfe.*` | `nfe_danfe` |

## Fases

### Fase 0 — Prova técnica (risco principal)
- Carregar .pfx (chave privada + cadeia) com pointycastle/asn1lib.
- C14N inclusiva (`http://www.w3.org/TR/2001/REC-xml-c14n-20010315`) + transform enveloped.
- Assinar `infNFe` e comparar **byte a byte** com a saída do Zeus para o mesmo XML/certificado.
- `NfeStatusServico` em homologação via `HttpClient` + `SecurityContext`.
- **Pronto quando:** assinatura idêntica e cStat 107 em homologação.
- **Status (2026-11-17):** assinatura idêntica a byte ao `SignedXml` do .NET (SHA1 e SHA256), golden gerado por `tools/golden_assinatura`; PKCS#12 moderno (PBES2/AES) e legado (RC2-40/3DES) lidos. **Pendente:** cStat 107 com certificado A1 real (`packages/nfe/example/status_homologacao.dart`).
- **Descoberta (2026-11-17):** as SEFAZ pedem o certificado do cliente por renegociação TLS após a requisição HTTP; o BoringSSL do `dart:io` recusa (`NO_RENEGOTIATION`). Decisão: transporte plugável (`TransporteSoap`) com pilha nativa:
  - `dfe_transporte_ffi`: WinHTTP/SChannel (Windows, **validado contra SEFAZ-SP**: passa da renegociação) e libcurl/OpenSSL (Linux, não testado).
  - `dfe_flutter` (plugin Flutter): Android (JSSE, compila; renegociação a validar em aparelho), iOS/macOS (URLSession, não compilado — requer Mac).
  - Ponto de atenção Windows: chave importada com `PKCS12_NO_PERSIST_KEY` (provedor legado). Importar via CNG (`PKCS12_ALWAYS_CNG_KSP`) quebrou a conexão com a SEFAZ-SP.
- Observação: SDK local é Dart 3.4, então o monorepo usa melos 6 + dependências `path` (sem pub workspaces).

### Fase 1 — dfe_core + gerador
- Gerador lê `.cs` de `NFe.Classes`/`DFe.Classes`: propriedades, `[XmlElement]`, `[XmlAttribute]`, `[XmlIgnore]`, enums com `[XmlEnum]`, propriedades de formatação (`*Proxy`, decimais com N casas), ordem dos elementos.
- Gera classes Dart imutáveis com `toXml()` / `fromXml()`; pontos não traduzíveis automaticamente marcados para revisão manual.
- **Pronto quando:** ida e volta sem diferenças nos XMLs de `NFe.Utils.Testes`/`DFe.Testes` + XMLs reais.

### Fase 2 — NFC-e
- Autorização síncrona (`NFeAutorizacao` indSinc=1), consulta de protocolo, cancelamento (inclusive por substituição), inutilização.
- Montagem de `nfeProc`, QR Code v2 (online e contingência offline), `urlChave`.
- Contingência offline (tpEmis 9) e reenvio.
- **Pronto quando:** emitir/cancelar/inutilizar em homologação em ≥ 2 UFs (ex.: SVRS e SP).

### Fase 3 — NF-e
- Autorização assíncrona + `NFeRetAutorizacao` (recibo), CC-e, manifestação do destinatário, `NfeDistDFeInteresse` (descompactar docZip), `NfeConsultaCadastro`, EPEC.
- **Pronto quando:** paridade com esses métodos de `ServicosNFe` em homologação.

### Fase 4 — Impressão
- DANFE NFC-e 80mm (PDF e ESC/POS com QR Code), DANFE NF-e A4 retrato (PDF), eventos (CC-e/cancelamento) em PDF.
- **Pronto quando:** layout conferido contra os DANFEs do Zeus (QuestPdf) para os mesmos XMLs.

### Fora da v1
CT-e, MDF-e, eventos IBS/CBS da reforma tributária, A3, validação completa por XSD, Flutter Web.

## Testes
- Unitários com fixtures copiadas de `NFe.Utils.Testes` e `DFe.Testes`.
- Golden tests de assinatura (saída do Zeus como referência).
- Integração em homologação, habilitada por variáveis de ambiente (`DFE_PFX_PATH`, `DFE_PFX_SENHA`, `DFE_UF`) — nunca versionar certificados.

## Riscos
| Risco | Mitigação |
|---|---|
| C14N divergente → rejeição 297 | Fase 0 dedicada, golden tests byte a byte |
| PKCS#12 com algoritmos legados (RC2/3DES) | Suportar PBE legado no parser; fallback documentado |
| Diferenças de URL/versão por UF | Portar tabela do Zeus e cobrir com testes |
| Formatação de decimais/datas (TZD) | Portar regras de `DataHoraOffSet`/proxies via gerador |
