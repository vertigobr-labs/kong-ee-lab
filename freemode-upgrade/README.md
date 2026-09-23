# Free mode → VeeCode APIP: reaproveitando o database <!-- omit in toc -->

Cenário que sobe o Kong Gateway Enterprise em "free mode", popula um database Postgres com o
schema dele, e depois aponta uma imagem baseada em Kong OSS (VeeCode APIP) para o **mesmo**
database.

O objetivo é responder a uma pergunta prática: quem está em free mode e precisa sair dele (porque
o free mode deixou de existir) consegue trocar só a imagem, mantendo o banco?

- [Contexto](#contexto)
- [Pré-requisitos](#pré-requisitos)
- [Etapa 1: Kong EE 3.9 em free mode](#etapa-1-kong-ee-39-em-free-mode)
- [Etapa 2: trocar para o VeeCode APIP](#etapa-2-trocar-para-o-veecode-apip)
- [O erro](#o-erro)
- [A solução e o que ela deixa para trás](#a-solução-e-o-que-ela-deixa-para-trás)
- [Deixando o compose resolver sozinho](#deixando-o-compose-resolver-sozinho)
- [Rollback](#rollback)
- [Recomendações](#recomendações)
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

Ou seja, a troca deste cenário é ao mesmo tempo:

- uma **mudança de edição**: Enterprise → OSS
- uma **mudança de versão**: 3.9 → 3.10

## Pré-requisitos

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com o plugin `docker compose`

## Etapa 1: Kong EE 3.9 em free mode

```sh
docker compose up -d kong-db
docker compose up kong-ee-init    # bootstrap do schema
docker compose up -d kong-ee
```

O bootstrap do Enterprise aplica **145 migrations** e cria **90 tabelas** — contra 67 migrations do
Kong OSS. A diferença é o schema Enterprise: RBAC, workspaces, licenças, auditoria, vitals.

Confirme que está em free mode (`edition: enterprise`, sem licença) e crie uma API para ter dados
reais no banco:

```sh
curl -s localhost:8001/ | jq '{version, edition, license}'

curl -s -X POST localhost:8001/services \
  -d name=cep -d url=http://viacep.com.br/ws
curl -s -X POST localhost:8001/services/cep/routes \
  -d name=cep-route -d 'paths[]=/cep' -d strip_path=true

curl -s localhost:8000/cep/20020080/json | jq -r .logradouro
```

## Etapa 2: trocar para o VeeCode APIP

Derrube o Enterprise **preservando o volume do banco** e suba o APIP no lugar:

```sh
docker compose stop kong-ee && docker compose rm -f kong-ee
docker compose up apip
```

## O erro

O APIP não sobe:

```pre
[error] init_by_lua error: /usr/local/share/lua/5.1/kong/cmd/utils/migrations.lua:20:
New migrations available; run 'kong migrations up' to proceed
stack traceback:
        [C]: in function 'error'
        .../kong/cmd/utils/migrations.lua:20: in function 'check_state'
        /usr/local/share/lua/5.1/kong/init.lua:678: in function 'init'
```

O container sai com código 1.

A mensagem parece trivial ("é só rodar as migrations"), mas a causa é mais sutil do que um upgrade
de versão comum. O Kong valida, no boot, se o ledger de migrations do banco (tabela `schema_meta`)
bate com o conjunto de migrations que **aquele binário** conhece. O banco foi escrito pelo
Enterprise, cujo ledger é um superconjunto com nomes próprios; o binário OSS encontra ali um estado
que não reconhece como completo.

## A solução e o que ela deixa para trás

```sh
docker compose run --rm --no-deps apip kong migrations up
docker compose up -d apip
```

Resultado observado:

```pre
migrating core on database 'kong'...
core migrated up to: 014_230_to_270 (executed)
core migrated up to: 015_270_to_280 (executed)
2 migrations processed
2 executed
```

Depois disso **o APIP sobe e funciona**: a Admin API responde `3.10.0-veecode.10` com
`edition: community`, o service e a route criados no Enterprise continuam lá, e o proxy responde
normalmente.

**Mas repare no que foi aplicado.** As duas migrations executadas são `014_230_to_270` e
`015_270_to_280` — migrations antigas, da época do 2.3 → 2.8, e não do 3.9 → 3.10. Isso acontece
porque a numeração das migrations de `core` diverge entre OSS e Enterprise: o banco fica com
`015_270_to_280` **e** `016_270_to_280` registradas, duas migrations de nomes diferentes para a
mesma transição. O que o OSS fez foi preencher lacunas do seu próprio ledger, não migrar de versão.

O schema resultante é híbrido. Depois da troca, o banco ainda tem:

- **91 tabelas** (o OSS sozinho cria bem menos)
- **11 subsistemas `enterprise*`** registrados em `schema_meta`
- **17 tabelas órfãs** que o APIP nunca vai ler nem limpar: `rbac_roles`, `rbac_users`,
  `rbac_user_roles`, `rbac_role_endpoints`, `rbac_role_entities`, `rbac_user_groups`,
  `workspaces`, `workspace_entities`, `workspace_entity_counters`, `licenses`, `license_data`,
  `audit_objects`, `audit_requests`, `consumer_group_*`, `vitals_code_classes_by_workspace`
- a tabela `workspaces` com 1 linha (o workspace `default` do Enterprise), inerte para o OSS

Ou seja: **funciona, mas não é uma migração limpa.** É um banco Enterprise sendo operado por um
binário OSS, com dívida de schema acumulada e um ledger de migrations inconsistente entre as duas
edições. Nada disso é suportado pela Kong — a documentação cobre upgrades dentro da mesma edição,
não Enterprise → OSS.

## Deixando o compose resolver sozinho

O passo manual acima pode ser automatizado, e o compose deste cenário já traz isso pronto no
perfil `auto`:

```sh
docker compose --profile auto up apip-auto
```

Isso funciona tanto em um banco **vazio** quanto em um banco **vindo do Enterprise**, sem decidir
nada antes: os três comandos de migration do Kong são idempotentes e saem com código 0 quando não
há o que fazer.

| Comando | Banco vazio | Banco já populado |
| --- | --- | --- |
| `kong migrations bootstrap` | aplica o schema | `Database already bootstrapped` — exit 0 |
| `kong migrations up` | `Database needs bootstrapping` — **exit 1** | aplica o pendente, ou `Database is already up-to-date` — exit 0 |
| `kong migrations finish` | nada a fazer — exit 0 | `No pending migrations to finish` — exit 0 |

Como só o `up` falha em banco vazio, a ordem `bootstrap` → `up` → `finish` cobre os dois casos e é
segura de rodar a cada `docker compose up`.

O detalhe é **como** encadear. O idioma usual seria um `sh -c "kong migrations bootstrap && kong
migrations up"`, mas a imagem distroless não tem shell:

```sh
docker run --rm --entrypoint /bin/sh veecode/kong:3.10.0-veecode.10-distroless -c "echo oi"
# OCI runtime create failed: no such file or directory
```

Não há `/bin/sh`, `/bin/bash` nem `/usr/bin/sh` — é exatamente o ponto da variante distroless. Duas
saídas:

1. **Um serviço por comando, encadeados pelo próprio compose** (o que este cenário faz). Cada
   serviço roda um único comando e o próximo espera pelo anterior com
   `condition: service_completed_successfully`. Não precisa de shell e funciona na distroless.
2. **Usar a imagem regular só para as migrations** e a distroless em runtime. A tag
   `veecode/kong:3.10.0-veecode.10` (sem `-distroless`) tem shell, então aceita `sh -c`. É o padrão
   "toolbox para migrar, distroless para servir".

**Mas automatizar não limpa nada.** O perfil `auto` só evita o passo manual — o banco resultante
continua sendo o mesmo híbrido descrito acima. A diferença fica evidente comparando os dois
caminhos:

| | Banco nascido no APIP/OSS | Banco herdado do Enterprise |
| --- | --- | --- |
| Tabelas | **35** | **91** |
| Subsistemas `enterprise*` em `schema_meta` | 0 | 11 |

São 56 tabelas a mais que o gateway nunca vai usar. Automatizar a migration torna o caminho
conveniente, não correto.

## Rollback

Voltar para o Enterprise 3.9.1.2 depois da troca também funciona: ele sobe, reconhece o banco e os
dados continuam íntegros. Isso dá uma janela de volta segura durante um teste.

```sh
docker compose stop apip && docker compose rm -f apip
docker compose up -d kong-ee
```

Não confie nisso indefinidamente: assim que qualquer entidade nova for criada pelo APIP, ou
qualquer migration futura do OSS for aplicada, o caminho de volta deixa de ser garantido.

## Recomendações

Em ordem de preferência, para sair do free mode:

1. **Exportar e reimportar com decK** (recomendado). Em vez de reaproveitar o banco, faça
   `deck gateway dump` no Enterprise, suba o APIP com um banco **novo e vazio**, e aplique com
   `deck gateway sync`. A configuração é migrada, o schema nasce limpo e sem tabelas órfãs, e o
   ledger de migrations fica coerente. É mais trabalho, e é o único caminho que resulta em um
   ambiente sustentável.

2. **Reaproveitar o banco como neste laboratório**, aceitando a dívida. Aceitável para um teste,
   uma prova de conceito ou uma janela curta de transição. Se for por esse caminho, faça
   `pg_dump` antes, e documente que aquele banco carrega schema Enterprise órfão.

3. **Limpar o schema Enterprise manualmente** depois da troca (`DROP TABLE` nas órfãs, remover os
   subsistemas `enterprise*` de `schema_meta`). Não recomendado: exige conhecer as dependências
   entre as tabelas, não é suportado, e o resultado ainda difere de um banco nascido no OSS.

4. **Assinar uma licença Enterprise** e seguir na linha 3.10+. É a opção se os recursos
   Enterprise (RBAC, workspaces, auditoria) estiverem realmente em uso — nenhum deles existe no
   OSS, e este laboratório só é indolor porque o free mode não dá acesso a eles.

Vale notar que sair do free mode via APIP **não é uma perda de funcionalidade**: em free mode os
recursos Enterprise já estavam desligados. O que se ganha é uma imagem com cadência de patch e
superfície de ataque menor; o que se perde é o caminho de upgrade para o Enterprise licenciado.

## Limpeza

```sh
docker compose down -v
```
