# Free mode → VeeCode APIP: reaproveitando o database <!-- omit in toc -->

Cenário que sobe o Kong Gateway Enterprise em "free mode", popula um database Postgres com o
schema dele, e depois migra para uma imagem baseada em Kong OSS (VeeCode APIP).

**O que se descreve aqui anda em duas direções ao mesmo tempo**, e é isso que torna o caso
diferente de um upgrade comum:

- é um **upgrade de release**, do Kong 3.9 para o 3.10+ do APIP;
- e é, ao mesmo tempo, um **downgrade de schema**, do schema Enterprise para o do OSS.

O `kong migrations up` sabe subir de release, mas não sabe descer de edição — e é dessa segunda
direção que vem tudo o que dá errado no roteiro.

O roteiro percorre os **dois caminhos** para sair do free mode e compara o resultado dos dois no
banco:

1. **Reaproveitar o database** — troca só a imagem. Funciona, mas deixa 56 tabelas fantasmas.
2. **Recriar a partir de um backup do decK** — banco novo, schema limpo, configuração restaurada.

- [Contexto](#contexto)
- [Pré-requisitos](#pré-requisitos)
- [Etapa 1: Kong EE 3.9 em free mode](#etapa-1-kong-ee-39-em-free-mode)
- [Etapa 2: backup com decK](#etapa-2-backup-com-deck)
- [Etapa 3: caminho A — reaproveitar o database](#etapa-3-caminho-a--reaproveitar-o-database)
- [Etapa 4: caminho B — destruir e recriar](#etapa-4-caminho-b--destruir-e-recriar)
- [Etapa 5: limpar o dump](#etapa-5-limpar-o-dump)
- [Até onde o script vai](#até-onde-o-script-vai)
- [Etapa 6: validate, diff e sync](#etapa-6-validate-diff-e-sync)
- [Comparação final](#comparação-final)
- [Recomendações](#recomendações)
- [A mesma coisa em Kubernetes](#a-mesma-coisa-em-kubernetes)
- [Limpeza](#limpeza)

## Contexto

O "free mode" do Kong Gateway Enterprise — rodar a imagem Enterprise sem licença — foi
**removido na versão 3.10**. A partir dela, rodar sem licença passa a se comportar como rodar com
licença expirada. A última versão Enterprise que ainda suporta free mode é a linha **3.9**, e a
última tag dessa linha é `3.9.1.2`.

O [VeeCode APIP](https://hub.docker.com/r/veecode/kong) é uma distribuição endurecida do Kong
Gateway **OSS**, mantida pela Vertigo: imagens multi-arch baseadas em RHEL 10, RPMs assinados e um
gate de segurança via SBOM. A variante `-distroless` não tem shell, gerenciador de pacotes nem
`curl`. A versão usada aqui é `3.10.0-veecode.10-distroless`, que corresponde ao Kong OSS 3.10.

## Pré-requisitos

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com o plugin `docker compose`
- [decK](https://docs.konghq.com/deck/) (testado com a v1.62)
- [yq](https://github.com/mikefarah/yq) v4, usado pelo script de limpeza

## Etapa 1: Kong EE 3.9 em free mode

```sh
docker compose up -d kong-ee
```

O bootstrap do Enterprise aplica **145 migrations** e cria **90 tabelas** — contra 67 migrations do
Kong OSS. A diferença é o schema Enterprise: RBAC, workspaces, licenças, auditoria, vitals.

Confirme que está em free mode (`edition: enterprise`, sem licença) e crie alguma configuração
para ter dados reais no banco:

```sh
curl -s localhost:8001/ | jq '{version, edition, license}'

curl -s -X POST localhost:8001/services -d name=cep -d url=http://viacep.com.br/ws
curl -s -X POST localhost:8001/services/cep/routes \
  -d name=cep-route -d 'paths[]=/cep' -d strip_path=true
curl -s -X POST localhost:8001/consumers -d username=app1
curl -s -X POST localhost:8001/consumers/app1/key-auth -d key=segredo123
curl -s -X POST localhost:8001/services/cep/plugins \
  -d name=rate-limiting -d config.minute=20 -d config.policy=local
curl -s -X POST localhost:8001/services/cep/plugins -d name=key-auth

curl -s -H "apikey: segredo123" localhost:8000/cep/20020080/json | jq -r .logradouro
```

Note que o free mode já bloqueia as entidades Enterprise: `POST /consumer_groups` e `/rbac/users`
respondem **403**.

## Etapa 2: backup com decK

**Antes de qualquer migration**, tire o backup da configuração. É ele que torna o caminho B
possível:

```sh
deck gateway dump --kong-addr http://localhost:8001 -o kong.yaml
```

## Etapa 3: caminho A — reaproveitar o database

Derrube o Enterprise **preservando o volume do banco** e suba o APIP no lugar:

```sh
docker compose stop kong-ee && docker compose rm -f kong-ee
docker compose up -d apip
```

O compose resolve as migrations sozinho: antes de subir o gateway ele encadeia
`kong migrations bootstrap` → `up` → `finish`. Os três são idempotentes e saem com código 0 quando
não há o que fazer, então a mesma cadeia serve para um banco novo e para este, herdado do
Enterprise.

O APIP sobe e funciona — `edition: community`, e a configuração criada no Enterprise continua lá.
**Mas não é uma migração limpa.**

Repare no que a migration aplicou: `014_230_to_270` e `015_270_to_280` — migrations antigas, da
época do 2.3 → 2.8, e não do 3.9 → 3.10. A numeração das migrations de `core` diverge entre OSS e
Enterprise, e o banco acaba com `015_270_to_280` **e** `016_270_to_280` registradas, duas migrations
de nomes diferentes para a mesma transição. O OSS preencheu lacunas do próprio ledger, não migrou
de versão.

O que sobra no schema:

```sh
docker compose exec kong-db psql -U kong -d kong -c \
  "select count(*) from information_schema.tables where table_schema='public'"
docker compose exec kong-db psql -U kong -d kong -c \
  "select count(*) from schema_meta where subsystem like 'enterprise%'"
```

**91 tabelas** e **11 subsistemas `enterprise*`** em `schema_meta`. São 56 tabelas a mais do que um
banco nascido no OSS — tabelas que o gateway nunca vai ler nem limpar: `rbac_roles`, `rbac_users`,
`rbac_user_roles`, `rbac_role_endpoints`, `rbac_role_entities`, `rbac_user_groups`,
`workspace_entities`, `workspace_entity_counters`, `licenses`, `license_data`, `audit_objects`,
`audit_requests`, `consumer_group_*` e `vitals_*`.

Atenção a uma exceção que confunde: a tabela `workspaces` **não** é fantasma. Ela existe também no
schema puro do Kong OSS 3.10, com uma linha (o workspace `default`). O vestígio Enterprise são as
`workspace_entities` e `workspace_entity_counters`.

Nada disso é suportado pela Kong: a documentação cobre upgrades dentro da mesma edição, não
Enterprise → OSS.

## Etapa 4: caminho B — destruir e recriar

Agora o caminho limpo. Jogue o banco fora e deixe o APIP criar o schema dele do zero:

```sh
docker compose down -v
docker compose up -d apip
```

O mesmo encadeamento de migrations roda, mas desta vez em um banco vazio: o `bootstrap` cria o
schema OSS e o `up`/`finish` não têm o que fazer. Resultado: **35 tabelas**, **zero** subsistemas
`enterprise*` — e nenhuma configuração, porque o banco é novo.

## Etapa 5: limpar o dump

Tente sincronizar o backup como ele saiu do Enterprise:

```sh
deck gateway validate kong.yaml --kong-addr http://localhost:8001
```

```pre
Error: validate entity 'plugins (key-auth)': HTTP status 400
(message: "2 schema violations (protocols.5: expected one of: grpc, grpcs, http, https;
 protocols.6: expected one of: grpc, grpcs, http, https)")
```

O plugin `key-auth` do Enterprise aceita os protocolos `ws` e `wss`; o equivalente OSS não. É um
exemplo de configuração que atravessa o dump e precisa sair antes do sync.

O script `clean-enterprise.sh` desta pasta faz essa limpeza. Ele foi escrito **a partir** do que o
`validate` reclamou — é assim que se estende: rode o validate, veja o que ele recusa, acrescente
uma regra, rode de novo.

```sh
./clean-enterprise.sh kong.yaml > kong-oss.yaml
```

Além dos protocolos `ws`/`wss`, o script já remove `_workspace`, `workspaces`, `consumer_groups`,
`rbac_roles`, `rbac_users`, `licenses` e a chave `groups` dentro de `consumers` — entidades que não
aparecem em um dump de free mode, mas apareceriam em um dump de uma instalação licenciada.

## Até onde o script vai

A lista de exclusões do `clean-enterprise.sh` **não é exaustiva** — ela cobre este cenário, não o
universo Enterprise.

Para um dump de **free mode**, como o deste roteiro, ela é suficiente, e por um motivo que dá para
verificar:

```sh
curl -s localhost:8001/ | jq -r '.plugins.available_on_server | keys[]' | sort
```

Rodando isso contra o Kong EE 3.9.1.2 em free mode e contra o APIP 3.10, sai **a mesma lista de 45
plugins**. Em free mode o gateway Enterprise não carrega nenhum plugin Enterprise, então nenhum
deles pode chegar ao dump. Somado ao fato de que `POST /consumer_groups` e `/rbac/users` respondem
403, sobra pouca coisa que o dump de free mode possa carregar de Enterprise — na prática, os
protocolos `ws`/`wss`.

Para um dump de uma instalação **licenciada**, a história é outra, e o script fica bem aquém:

- **Plugins Enterprise** são a maior lacuna. `openid-connect`, `rate-limiting-advanced`,
  `request-validator`, `mtls-auth`, `saml`, `oas-validation` e dezenas de outros aparecem no dump
  com a configuração deles, e o script não tem regra para nenhum. O sync falha em cada um.
- **Campos Enterprise dentro de plugins compartilhados**, na mesma linha do `ws`/`wss` que
  encontramos.
- **Entidades de workspace** além do `_workspace`, se o dump foi feito com `--all-workspaces`.
- **Recursos de RBAC**, se foram exportados à parte com `--rbac-resources-only`.

Não faz sentido tentar antecipar essa lista aqui: ela muda a cada release do Kong e depende de
quais recursos Enterprise a instalação de origem realmente usava. O procedimento é o que a etapa
anterior mostra — rodar `deck gateway validate`, ler o que ele recusa, acrescentar uma regra, e
repetir até passar limpo. O `validate` é a fonte da verdade, não o script.

## Etapa 6: validate, diff e sync

```sh
deck gateway validate kong-oss.yaml --kong-addr http://localhost:8001   # sem violações
deck gateway diff     kong-oss.yaml --kong-addr http://localhost:8001   # 6 a criar
deck gateway sync     kong-oss.yaml --kong-addr http://localhost:8001
```

Confira que a configuração voltou inteira, incluindo a credencial do consumer:

```sh
curl -s -o /dev/null -w "%{http_code}\n" localhost:8000/cep/20020080/json   # 401
curl -s -H "apikey: segredo123" localhost:8000/cep/20020080/json | jq -r .logradouro
deck gateway diff kong-oss.yaml --kong-addr http://localhost:8001           # 0/0/0
```

## Comparação final

```sh
docker compose exec kong-db psql -U kong -d kong -c \
  "select table_name from information_schema.tables where table_schema='public'
   and (table_name like 'rbac\_%' or table_name like 'audit\_%'
        or table_name like '%license%' or table_name like 'vitals\_%'
        or table_name like 'consumer\_group%' or table_name like 'workspace\_%')"
```

Cuidado ao escrever essa consulta: em `LIKE` do SQL o `_` é curinga de um caractere, então
`workspace_%` sem escape casa com `workspaces` e dá um falso positivo.

| | Caminho A (reaproveitar) | Caminho B (decK) |
| --- | --- | --- |
| Tabelas | 91 | **35** |
| Subsistemas `enterprise*` | 11 | **0** |
| Tabelas fantasmas | 56 | **nenhuma** |
| Ledger de migrations | inconsistente entre edições | coerente |
| Configuração preservada | sim, automaticamente | sim, via `deck sync` |
| Suportado pela Kong | não | sim (é uma instalação OSS comum) |

Os dois terminam com o gateway funcionando e a mesma configuração no ar. A diferença está no banco.

## Recomendações

1. **Caminho B (decK) é o recomendado.** O schema nasce limpo, o ledger de migrations fica
   coerente e o resultado é indistinguível de uma instalação OSS nova. O custo é a janela de
   indisponibilidade entre destruir e recriar, e o trabalho de limpar o dump.

2. **Caminho A serve para um teste, uma prova de conceito ou uma janela curta de transição.**
   Se for por ele, faça `pg_dump` antes e documente que aquele banco carrega schema Enterprise
   órfão.

3. **Limpar o schema Enterprise manualmente** depois do caminho A (`DROP TABLE` nas órfãs) não é
   recomendado: exige conhecer as dependências entre as tabelas, não é suportado, e o resultado
   ainda difere de um banco nascido no OSS. Se o objetivo é um schema limpo, o caminho B chega lá
   com menos risco.

4. **Assinar uma licença Enterprise** e seguir na linha 3.10+ é a opção se os recursos Enterprise
   (RBAC, workspaces, auditoria) estiverem realmente em uso — nenhum deles existe no OSS, e este
   laboratório só é indolor porque o free mode não dá acesso a eles.

Vale notar que sair do free mode via APIP **não é uma perda de funcionalidade**: em free mode os
recursos Enterprise já estavam desligados. O que se ganha é uma imagem com cadência de patch e
superfície de ataque menor; o que se perde é o caminho de upgrade para o Enterprise licenciado.

## A mesma coisa em Kubernetes

O [VKDR.md](VKDR.md) refaz o destino deste roteiro em um cluster k3d com a CLI do `vkdr`: Kong em
modo standard com a imagem distroless do APIP, partindo do `kong-oss.yaml` já limpo. Lá aparecem
dois problemas que o docker compose não tem — os init containers do chart oficial não rodam em
imagem sem shell, e o Ingress Controller disputa o banco com o decK.

## Limpeza

```sh
docker compose down -v
rm -f kong.yaml kong-oss.yaml
```
