# dfe_dart — Levantamento do que falta

> 2026-11-17. Referência: o que o ZeusFiscal cobre × o que o `dfe_dart` já tem.
> Prioridade: **P1** = necessário para uso em produção · **P2** = importante logo depois · **P3** = quando surgir a demanda.

## 0. Princípios (definidos em 2026-11-17)

1. **Biblioteca anêmica e genérica.** O `dfe_dart` expõe APIs para *qualquer* app (PDV, ERP, e-commerce, app de entregas...). Nada específico de PDV entra nos pacotes; o app de exemplo é só demonstração.
2. **Paridade com o Zeus como régua.** Se o Zeus faz, o `dfe_dart` faz; se o Zeus não faz, fica com o app.
   - **Contingência automática** (detecção, fila, worker, prazos): o Zeus **não faz** → **fora do escopo**. A biblioteca oferece as peças: tipos de emissão, serviços por ambiente/SVC, QR de contingência, consulta de protocolo, eventos.
   - **Motor tributário** (regras de CST/alíquota/CFOP por produto/UF): o Zeus **não tem** → **fora do escopo**. O app (ex.: o PDV com SQLite) decide; a biblioteca recebe os valores e monta os grupos corretos, como o `ICMSGeral` do Zeus.
3. **Escopo de UF:** todas as 27 UFs; regimes Simples e normal; com ST e monofásicos. Operações interestaduais (DIFAL) por demanda.

> As seções 2 (motor tributário) e 3 (contingência) abaixo ficam como **referência para o app** — não serão implementadas na biblioteca, exceto os itens marcados como "biblioteca".

## 1. Tributação do item (ICMS, PIS/COFINS, IPI, outros)

### 1.1 ICMS — o que existe × o que falta

| Grupo | CST/CSOSN | Uso típico | dfe_dart | Prio |
|---|---|---|---|---|
| ICMS00 | 00 | tributada integralmente | ✅ (sem FCP ST) | — |
| ICMS10 | 10 | tributada + ST | ✅ falta FCP/FCP-ST e `vICMSSTDeson` | P2 |
| ICMS20 | 20 | redução de base | ✅ falta FCP e desoneração (`vICMSDeson`, `motDesICMS`) | P2 |
| ICMS30 | 30 | isenta/não tributada + ST | ❌ | P2 |
| ICMS40 | 40/41/50 | isenta, não tributada, suspensão | ✅ falta desoneração | P2 |
| ICMS51 | 51 | **diferimento** (`pDif`, `vICMSOp`, `vICMSDif`) | ❌ | P2 |
| ICMS60 | 60 | ST retido anteriormente | ✅ falta **ICMS efetivo** (`pRedBCEfet`, `vBCEfet`, `pICMSEfet`, `vICMSEfet`) — exigido por algumas UFs na NFC-e | **P1** |
| ICMS70 | 70 | redução + ST | ❌ | P2 |
| ICMS90 | 90 | outros | ❌ | **P1** (coringa usado por muitos ERPs) |
| ICMS02/15/53/61 | 02, 15, 53, 61 | **monofásico de combustíveis** (NT 2023.001) | ❌ | P3 (só postos) |
| ICMSPart | 10/90 | partilha entre UFs (operações específicas) | ❌ | P3 |
| ICMSST | 41/60 | repasse de ST retido | ❌ | P3 |
| ICMSUFDest | — | **DIFAL** consumidor final não contribuinte interestadual (NF-e) | ❌ | P2 (só se vender para outra UF) |
| ICMSSN101 | 101 | Simples com crédito | ✅ | — |
| ICMSSN102 | 102/103/300/400 | Simples sem crédito | ✅ validado SEFAZ | — |
| ICMSSN201/202 | 201/202/203 | Simples + ST | ✅ falta FCP-ST | P2 |
| ICMSSN500 | 500 | Simples, ST retido | ✅ falta ICMS efetivo | **P1** |
| ICMSSN900 | 900 | Simples outros | ⚠️ só `orig`+`CSOSN` (sem os grupos opcionais de ICMS/ST/crédito) | **P1** |

**FCP (Fundo de Combate à Pobreza):** hoje só no CST 00. Falta em 10, 20, 51, 70, 90, 201, 202, 900 e no ST (`vBCFCPST`, `pFCPST`, `vFCPST`) e retido (`vFCPSTRet`). Obrigatório em UFs com FCP (RJ, MG, AL, BA...) → **P1 se o PDV atender essas UFs**.

### 1.2 Federais

| Grupo | Situação | Prio |
|---|---|---|
| PIS/COFINS alíquota (01/02), NT (04–09), outros (49–99) | ✅ | — |
| PIS/COFINS por **quantidade** (03 — bebidas, combustíveis) | ❌ `PISQtde`/`COFINSQtde` | P2 |
| PIS-ST / COFINS-ST | ❌ | P3 |
| IPI tributado por alíquota / não tributado | ✅ | — |
| IPI por **unidade** (`qUnid`/`vUnid`) | ❌ | P3 |
| II (importação) | ❌ | P3 |
| ISSQN (serviços na NF-e conjugada) + `ISSQNtot` | ❌ | P3 (só se o PDV vender serviço) |

### 1.3 Reforma tributária (IBS/CBS/IS)

| Item | Situação | Prio |
|---|---|---|
| `IBSCBS` básico (CST, cClassTrib, IBS UF/Mun, CBS) + `IBSCBSTot` | ✅ autorizado SEFAZ-SP | — |
| Tabela oficial **CST × cClassTrib** com validação | ❌ (hoje o app informa livremente) | **P1** antes da obrigatoriedade |
| Redução de alíquota (`gRed`), diferimento (`gDif`), devolução de tributos (`gDevTrib`) | ❌ | P2 |
| Crédito presumido (`gCredPresOper`), tributação regular (`gTribRegular`), compra governamental | ❌ | P3 |
| Monofásico IBS/CBS (`gIBSCBSMono`) — combustíveis | ❌ | P3 |
| **IS** (Imposto Seletivo — bebidas, fumo...) | ❌ | P2 (a partir de 2027) |
| `vNFTot` (total com IBS/CBS/IS — 2027+) | ❌ | P2 |

## 2. Motor tributário

Hoje o **app decide** CST, alíquotas e base de cada item e a biblioteca só monta e calcula. Em um PDV isso precisa vir de regras cadastradas — é o "motor tributário".

**O que ele resolve:** dado *produto* + *operação* + *emitente* + *destinatário*, devolver os grupos `Icms`, `PisCofins`, `Ipi`, `IbsCbs` já preenchidos, o CFOP e o `cBenef`.

**Entradas**
- Emitente: UF, CRT (Simples/normal), regimes especiais.
- Produto: NCM, CEST, origem, EX TIPI, unidade, se é sujeito a ST/monofásico, perfil fiscal (grupo tributário do cadastro).
- Operação: natureza (venda, devolução, bonificação, remessa...), presencial/entrega, consumidor final.
- Destinatário: UF, contribuinte/não contribuinte (indIEDest), regime.

**Regras que ele precisa conter**
1. **Matriz CST/CSOSN × CRT × operação** (ex.: Simples → 102/500; normal → 00/60...).
2. **Alíquotas internas por UF** e interestaduais (4/7/12%), **FCP por UF**.
3. **ST:** MVA original e **MVA ajustada** (interestadual), pauta (PMPF), reduções de base, protocolos/convênios entre UFs.
4. **CFOP** automático (5.102/5.405/6.102/6.108/5.929...) a partir da operação, ST e destino.
5. **Benefícios fiscais (`cBenef`)** — obrigatórios em PR, RJ, RS, SC, GO, DF, ES... para CSTs com isenção/redução/diferimento.
6. **PIS/COFINS:** cumulativo × não cumulativo × monofásico (NCM em listas), Simples.
7. **IBS/CBS:** CST × cClassTrib por NCM/operação, alíquotas de transição por ano.
8. **Lei 12.741 (vTotTrib):** tabela IBPT por NCM (federal, estadual, municipal) com atualização.
9. **Validações cruzadas:** CST × CRT, CFOP × idDest, CEST obrigatório para NCM com ST, `cBenef` obrigatório por UF/CST.
10. **Arredondamento** padronizado (por item, rateios de desconto/frete — já existe `ratear()`).

**Proposta de arquitetura** (pacote novo `dfe_tributario`, Dart puro)
- `PerfilFiscal` (cadastro do produto) + `RegraTributaria` (matriz por UF/operação/CRT) → `MotorTributario.calcular(item, operacao) → ItemNfe` pronto.
- Tabelas como **dados** (JSON/SQLite fornecidos pelo PDV), não código: o PDV atualiza alíquotas/MVA/IBPT sem nova versão da biblioteca.
- Começar pelo cenário do PDV (venda interna a consumidor final, Simples e normal, ST retido) e crescer.
- **P1** (mínimo: CST/CFOP/alíquota interna/ST retido/IBPT/cBenef da UF do PDV).

## 3. Contingência — o que existe e o que falta

**Já existe:** NFC-e offline (tpEmis 9) com QR v3 assinado e transmissão manual dos pendentes; NF-e em SVC-AN/SVC-RS manual; DANFE com mensagens de contingência; reenvio de evento com horário da SEFAZ.

| # | Item | Por quê | Prio |
|---|---|---|---|
| C1 | **Detecção automática** de indisponibilidade: timeout, erro TLS/conexão, cStat 108/109 (serviço paralisado), 999 recorrente | o caixa não pode travar esperando a SEFAZ | **P1** |
| C2 | **Política de entrada/saída**: timeout curto configurável (ex.: 8–15 s), N falhas → contingência, *status* periódico para voltar ao normal | evitar ficar "preso" em contingência ou oscilar | **P1** |
| C3 | **Venda ambígua (timeout após enviar)**: antes de reemitir/contingenciar, **consultar a chave** (consSitNFe); se autorizada, usar o protocolo | evita nota duplicada e rejeição 204/539 | **P1** |
| C4 | **Fila persistente** de pendentes (SQLite/arquivo) com estado, tentativas, último erro, *backoff* e **worker em segundo plano** | hoje a transmissão é manual por botão | **P1** |
| C5 | **Prazo legal**: NFC-e offline transmitida em até 24 h (varia por UF); alertas de pendentes perto do prazo | multa/irregularidade | **P1** |
| C6 | **Rejeição de nota offline já entregue ao cliente**: fluxo de correção (emitir nova, cancelar, ou **cancelamento por substituição**) | a nota já foi impressa | **P1** |
| C7 | **Cancelamento por substituição** (evento 110112) — NFC-e offline que também foi autorizada online / duplicidade | previsto no MOC para NFC-e | **P1** |
| C8 | NF-e: verificar **se a SVC está ativa** (status na SVC) antes de usar; SVC exige ativação pela SEFAZ | evita rejeição em massa | P2 |
| C9 | NF-e: **EPEC** (evento 110140) — alternativa à SVC; e **FS-DA** (tpEmis 5, formulário de segurança) | quando SVC também cai | P2/P3 |
| C10 | **Lotes assíncronos pendentes** (recibo enviado, sem resposta): persistir recibo e consultar depois | não perder protocolo | P2 |
| C11 | **Relógio**: verificar desvio (NTP/`dhRecbto` da SEFAZ) e alertar; usar o desvio na `dhEmi`/`dhEvento` | vimos rejeição por horário | P2 |
| C12 | **Numeração**: reservar número de forma transacional (multi-caixa), definir série de contingência (se a UF exigir/for desejado) | evitar buracos/duplicidade | **P1** (no PDV) |
| C13 | **Inutilização** está desativada na SEFAZ-SP: definir o tratamento de números pulados | conformidade | P2 |
| C14 | **DANFE em contingência**: via do consumidor + via do estabelecimento quando a UF exigir; reimpressão | obrigações por UF | P2 |
| C15 | Auditoria/log de todas as transições normal ↔ contingência | fiscalização e suporte | P2 |

**Onde fica:** no **PDV** (o Zeus não tem contingência automática; pelo princípio "se o Zeus faz, faça; se não, não faça", a biblioteca não implementa). A biblioteca já fornece as peças: `consultarProtocolo` (C3), tpEmis 9/SVC/EPEC/FS-DA (C8–C9), `cancelarPorSubstituicao` (C6–C7), reenvio de evento com horário da SEFAZ (C11) e DANFE com mensagens de contingência (C14). O PDV implementa estado normal/contingência, fila persistente (SQLite), worker de retransmissão, prazos e numeração.

## 4. Outros itens para produção

| Item | Prio |
|---|---|
| **Validação por schema (XSD)** antes do envio — Dart não tem validador XSD; opções: libxml2 via FFI (Windows/Linux) ou validação estrutural própria nos grupos gerados | P2 |
| **Hash CSRT** no `infRespTec` (`GerarHashCSRT` do Zeus) — exigido por algumas UFs | **P1** se a UF exigir |
| NF-e **devolução / complementar / ajuste** (`finNFe` 2/3/4, `NFref`) | P2 |
| NF-e de **entrada** (tpNF 0) e **importação/exportação** | P3 |
| Identificação do consumidor na NFC-e acima do limite da UF; `indIntermed`/intermediador (marketplace/delivery) | P2 |
| **Manifestação do destinatário** e **distribuição DF-e** (notas de fornecedores) | P3 |
| Eventos novos da reforma (aceite de débito, crédito presumido, etc.) — o Zeus já tem | P3 |
| **PDF dos eventos** (CC-e, cancelamento) | P2 |
| Mensagens amigáveis para as **rejeições mais comuns** | P2 |
| **Certificado**: alerta de vencimento, armazenamento seguro da senha; A3 | P2 / P3 |
| **Desempenho**: o WinHTTP importa o .pfx a cada requisição; manter sessão/certificado em cache | P2 |
| **2ª UF** validada em homologação | P2 |
| **Plataformas**: Android (GPOS780S), Linux, iOS/macOS | P2 |
| **Gerador de modelos** (Fase 1) — adiado | P3 |

## 5. Escopo da biblioteca após os princípios (paridade com o Zeus)

| # | Item (biblioteca) | Zeus tem? |
|---|---|---|
| B1 | ✅ **(2026-11-18)** **Todos os grupos de ICMS**: 00, 02, 10, 15, 20, 30, 40/41/50, 51, 53, 60, 61, 70, 90, Part, ST, UFDest; Simples 101, 102/103/300/400, 201, 202/203, 500, 900 — com FCP, desoneração e ICMS efetivo | ✅ |
| B2 | ✅ **(2026-11-18)** **Seleção do grupo pelo CRT + CST/CSOSN** a partir de um objeto plano (equivalente ao `ICMSGeral`, `PISGeral`, `COFINSGeral`, `IPIGeral`) | ✅ |
| B3 | ✅ **(2026-11-18)** PIS/COFINS por quantidade e ST; IPI por unidade; II; ISSQN | ✅ |
| B4 | ✔️ **Feito (2026-11-18):** `IBSCBS` completo (gRed, gDif, gDevTrib, gTribRegular, gTribCompraGov, monofásico, transferência/ajuste/estorno de crédito, crédito presumido), `IS`/`ISTot`, `IBSCBSTot` completo e `vNFTot` — classes geradas do Zeus pelo extrator | ✅ |
| B5 | ✅ **(2026-11-18)** Tipos de emissão completos (`tpEmis` 2 FS, 3 SCAN, 4 EPEC, 5 FS-DA) | ✅ |
| B6 | ✔️ **Feito (2026-11-18):** `DetalheEvento` gerado do `detEvento` do Zeus (todos os campos e subgrupos: ator interessado, entrega/insucesso, conciliação, eventos da reforma), além dos montadores de cancelamento, CC-e, substituição, EPEC e manifestação. Ordem dos campos = Zeus (inclui `latGPS` antes de `dhEntrega`); não validado na SEFAZ | ✅ |
| B7 | ✅ **(2026-11-18)** **Hash CSRT** (`infRespTec`) — validado com o exemplo da NT; a sobrecarga do Zeus que recebe a NF-e usa "NFe" no lugar da chave (erro do Zeus) | ✅ |
| B8 | ✔️ **Feito (2026-11-18):** todos os grupos listados, inclusive exporta, compra, cana, agropecuário, `gCompraGov`, `gPagAntecipado`, `retTransp`, reboque/vagão/balsa e lacres. `vagao`/`balsa` seguem o schema (o Zeus os declara após `vol`) | ✅ |
| B9 | ⏸️ Fora do escopo por decisão (2026-11-18): distribuição DF-e, consulta de cadastro, download | — |
| B10 | **Feito (2026-11-18):** emissão anêmica no `dfe_nfe` e cálculos no `dfe_calculos`; regressão com XML idêntico ao anterior | — |

### 5.1 Paridade com o Zeus × extras do dfe_dart

**Verificado no código do Zeus:** ele **não calcula tributos** (não há código que gere `vICMS`, `vST`, `vPIS`, `vIBS`... a partir de base/alíquota), **não totaliza** a nota (`ICMSTot`/`vNF` são preenchidos pelo app; no EPEC ele só *copia* os totais da NF-e) e **não valida regras de negócio** (só o XSD). O que ele faz: **arredondar/formatar** nos próprios campos (2 casas em valores, 4 em alíquotas) e **escolher o grupo** pelo CRT + CST/CSOSN (`ICMSGeral`, `PISGeral`...).

| Camada | Pacote | Reflete o Zeus? |
|---|---|---|
| Emissão: o app informa **todos** os valores (tributos e totais); a biblioteca escolhe o grupo, arredonda/formata, monta, assina e transmite | `dfe_core`, `dfe_nfe` | ✅ **Paridade** |
| `CalculadoraTributos` (ICMS/ST/FCP/PIS/COFINS/IPI/IBS-CBS a partir de base e alíquota), totalização da nota, `ratear`, textos automáticos de homologação, validações de negócio (pagamento × total, IPI em NFC-e...) | **`dfe_calculos`** (novo, opcional) | ❌ **Não existe no Zeus** — extra documentado como tal; o app usa se quiser |
| DANFE (texto/PDF/ESC-POS/PNG) | `dfe_danfe`, `dfe_flutter` | ⚠️ O Zeus tem DANFE (FastReport/QuestPDF); o formato e a separação "gera × imprime" são do dfe_dart |
| Transporte nativo (renegociação TLS) | `dfe_transporte_ffi`, `dfe_flutter` | ⚠️ Necessidade do Dart; o Zeus usa a pilha do .NET |

**Regra para os próximos itens:** tudo em `dfe_core`/`dfe_nfe` deve ter equivalente no Zeus; o que não tiver vai para `dfe_calculos` (ou fica com o app), sempre marcado como "não existe no Zeus" na documentação.

## 6. Sugestão de ordem para a próxima etapa (versão original, focada em PDV — substituída pela seção 5)

1. **Contingência automática** (C1–C7, C12): detecção, consulta antes de reenviar, fila persistente com worker, prazo, cancelamento por substituição.
2. **ICMS completo para o PDV**: CST 90, CSOSN 900 completo, ICMS efetivo (60/500), FCP em todos os grupos.
3. **Motor tributário mínimo** (`dfe_tributario`) com as regras da UF do PDV + IBPT + cBenef.
4. Tabela CST × cClassTrib do IBS/CBS; CSRT se a UF exigir.
5. Itens P2 conforme a necessidade do PDV.

**Perguntas para definir o escopo**
- Em quais **UFs** o PDV vai operar? (define FCP, cBenef, ICMS efetivo, CSRT, prazos de contingência)
- Os clientes são **Simples**, **regime normal** ou ambos?
- Vende produtos com **ST** (bebidas, autopeças, cosméticos...) ou **monofásicos** (combustíveis)?
- Vende para **outras UFs** (DIFAL) ou só no balcão?
- Onde o PDV guarda dados (SQLite, servidor)? — define a fila de contingência e as tabelas do motor.

## 6. Próximos passos (2026-11-18)

**Biblioteca:** B1–B8 e B10 concluídos; B9 fora do escopo. Pendências:
- Validar na SEFAZ: tributação anêmica + `dfe_calculos`, CSRT, substituição, EPEC, manifestação, IBS/CBS completo, grupos complementares e eventos novos.
- CC-e: o reenvio com o horário da SEFAZ **não resolveu** o cStat 999 na SEFAZ-SP — investigar (só relevante se o PDV usar CC-e).
- P2: cache do certificado no WinHTTP, PDF de eventos, XSD, mensagens de rejeição, 2ª UF, outras plataformas.

**PDV (implementação no app, fora da biblioteca):**
1. Motor tributário (seção 2) — começar pelo cenário real: venda interna a consumidor final, Simples e normal, ST retido, IBPT; alimenta as regras do `dfe_calculos`.
2. Emissão online com fila persistente e consulta da chave em caso de timeout (C3/C4).
3. Contingência offline (C1, C2, C5, C6, C12) e guarda dos XML autorizados e eventos por 5 anos.
4. Dependência dos pacotes pelo Git (`git:` + `path:`), sem publicar no pub.dev.
