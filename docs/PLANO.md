# dfe_dart — Plano e estado (NF-e + NFC-e)

Porte para Dart/Flutter do [ZeusFiscal](https://github.com/Hercules-NET/ZeusFiscal) (.NET), referência local:
`D:\Pessoas\Outros\Projetos\zeus_fiscal`.

> Última atualização: 2026-11-17. Validado em **homologação na SEFAZ-SP, Windows**.

## Decisões

| Tema | Decisão |
|---|---|
| Escopo v1 | NF-e (mod. 55) e NFC-e (mod. 65), layout 4.00 |
| Modelos | Modelo simplificado escrito à mão (`DadosNfe`); gerador a partir de `NFe.Classes` (C#) ainda pendente — substituirá o modelo aos poucos |
| Certificado | Somente A1 (.pfx). A3 fora da v1 |
| Plataformas | Windows (validado); Android, Linux, iOS/macOS implementados, não validados. **Sem Flutter Web** |
| Transporte | Plugável (`TransporteSoap`). `dart:io` não serve: as SEFAZ pedem o certificado por **renegociação TLS** e o BoringSSL recusa. Pilha nativa: WinHTTP/SChannel (Windows), libcurl (Linux), JSSE (Android), URLSession (Apple) |
| QR Code NFC-e | v3 (NT 2025.001, sem CSC; em contingência assinado com o certificado) por padrão; v2 (CSC) opcional |
| Impressão | A biblioteca **gera** (texto, PDF, PNG, bytes ESC/POS); o **app imprime** |
| Licença | LGPL-2.1 (obra derivada do Zeus) |
| API | Assíncrona (`Future`), configuração imutável injetada |
| SDK | Dart 3.4 local → melos 6 + dependências `path` (sem pub workspaces) |

## Estrutura

```
dfe_dart/
  packages/
    dfe_core/            # PKCS#12, C14N, XMLDSig, SOAP 1.2, TransporteSoap
    dfe_nfe/             # NF-e/NFC-e: montagem, QR Code, serviços, eventos, URLs
    dfe_transporte_ffi/  # WinHTTP (Windows) e libcurl (Linux) via FFI
    dfe_danfe/           # DANFE NFC-e (texto/PDF/ESC-POS) e NF-e A4 (PDF)
    dfe_flutter/         # plugin: transporte Android/Apple, PNG do DANFE, app de exemplo
  tools/
    golden_assinatura/   # .NET: gera a assinatura de referência (lógica do Zeus)
  docs/
```

## Estado por fase

### Fase 0 — Prova técnica ✅
- Assinatura **idêntica byte a byte** ao `SignedXml` do .NET (SHA1/SHA256), golden em `tools/golden_assinatura`.
- PKCS#12 moderno (PBES2/AES) e legado (RC2-40/3DES).
- Status do serviço (cStat 107) via transporte nativo.
- Windows: chave importada com `PKCS12_NO_PERSIST_KEY`; importar via CNG (`PKCS12_ALWAYS_CNG_KSP`) quebrou a conexão com a SEFAZ-SP.

### Fase 1 — Gerador de modelos ⏸ adiado
- Gerador lendo `NFe.Classes`/`DFe.Classes` (C#) → classes Dart com `toXml()`/`fromXml()`.
- Pronto quando: ida e volta sem diferenças em XMLs reais.
- **Adiado (2026-11-17):** o modelo simplificado atende o PDV. Retomar quando for preciso ler XMLs de terceiros (DF-e) ou cobrir segmentos específicos.

### Fase 2 — NFC-e ✅ (SP)
- Autorização síncrona, consulta, cancelamento, contingência offline (tpEmis 9) com reenvio, QR Code v2/v3.
- Inutilização implementada; **SEFAZ-SP retorna 998 (serviço desativado)** — botões removidos do app.
- Tabela completa de URLs (27 UFs, NF-e/NFC-e, produção/homologação, SVC-AN/RS, QR Code v2/v3 e consulta) gerada do Zeus por `tools/exportar_urls`.
- Pendente: validação em uma 2ª UF.

### Fase 3 — NF-e ✅ parcial
- Feito: autorização síncrona/assíncrona (recibo), contingência SVC-AN/SVC-RS, consulta, cancelamento.
- CC-e (evento 110110) implementada. Na SEFAZ-SP retornou 999 com o servidor de eventos ~10 s atrasado; a biblioteca reenvia com o horário de registro da SEFAZ. **Reenvio ainda não validado.**
- Pendente: manifestação do destinatário, distribuição DF-e, consulta de cadastro, EPEC.

### Fase 4 — Impressão ✅
- DANFE NFC-e: texto (48/32 col.), PDF bobina, PNG, ESC/POS (CP860/CP850/sem acento, QR nativo ou raster, corte, gaveta).
- DANFE NF-e: PDF A4 multipágina conforme MOC, PNG por folha, marcas d'água.
- Pendente: PDF de eventos (CC-e/cancelamento).

### Fase 5 — Tributação ampliada 🔧 em andamento
- ICMS (CRT 3: 00/10/20/40/41/50/60; Simples: 101/102/103/201/202/300/400/500/900), PIS/COFINS (alíquota, NT, outras), IPI.
- Desconto, frete, seguro e outras despesas por item; totais calculados.
- Pagamentos múltiplos, cartão (`card`), troco; `infRespTec`.

### Fase 6 — Reforma tributária ✅ (grupos básicos)
- Grupos IBS/CBS (NT 2025.002) no item e IBSCBSTot no total, alíquotas de teste 2026; **autorizado na SEFAZ-SP (cStat 100)**.
- Pendente: diferimento, redução, crédito presumido, monofásico, IS.

### Plataformas ⏳ pendente
- Validar Android (GPOS780S), Linux, iOS/macOS.

### Fora da v1
CT-e, MDF-e, A3, validação completa por XSD, Flutter Web.

## Testes
- Unitários por pacote (`dart test`), golden de assinatura, testes de rede do WinHTTP contra a SEFAZ-SP.
- Homologação manual pelo app de exemplo (Windows); XMLs gravados em `Documentos\dfe_dart\xml`.
- Nunca versionar certificados reais.

## Riscos
| Risco | Mitigação |
|---|---|
| C14N divergente → rejeição 297 | Golden byte a byte contra o .NET |
| Renegociação TLS em outras plataformas | Transporte nativo por plataforma; validar em cada uma |
| Diferenças de URL/versão por UF | Tabela gerada do Zeus; regenerar com `tools/exportar_urls` quando o Zeus atualizar |
| Regras de validação por UF (rejeições) | Testar em homologação por UF atendida |
