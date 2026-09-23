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
- [As tabelas fantasmas](#as-tabelas-fantasmas)
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

Ou seja, a troca deste cenário é ao mesmo tempo uma **mudança de edição** (Enterprise → OSS) e uma
**mudança de versão** (3.9 → 3.10).

## Pré-requisitos

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com o plugin `docker compose`

## Etapa 1: Kong EE 3.9 em free mode

```sh
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
docker compose up -d apip
```

O compose resolve as migrations sozinho: antes de subir o gateway ele encadeia
`kong migrations bootstrap` → `up` → `finish`. Os três são idempotentes e saem com código 0 quando
não há o que fazer, então a mesma cadeia serve para um banco novo e para este, herdado do
Enterprise. Aqui ela aplica duas migrations e o gateway sobe.

Confira que funcionou — o service e a route criados no Enterprise continuam lá:

```sh
curl -s localhost:8001/ | jq '{version, edition}'
curl -s localhost:8001/services | jq -r '.data[].name'
curl -s localhost:8000/cep/20020080/json | jq -r .logradouro
```

## As tabelas fantasmas

O APIP sobe e funciona, mas **não é uma migração limpa**. O banco continua sendo um banco
Enterprise operado por um binário OSS.

Repare no que a migration aplicou: `014_230_to_270` e `015_270_to_280` — migrations antigas, da
época do 2.3 → 2.8, e não do 3.9 → 3.10. A numeração das migrations de `core` diverge entre OSS e
Enterprise, e o banco acaba com `015_270_to_280` **e** `016_270_to_280` registradas, duas migrations
de nomes diferentes para a mesma transição. O OSS preencheu lacunas do próprio ledger, não migrou
de versão.

O que sobra no schema depois da troca:

| | Banco nascido no APIP/OSS | Banco herdado do Enterprise |
| --- | --- | --- |
| Tabelas | **35** | **91** |
| Subsistemas `enterprise*` em `schema_meta` | 0 | 11 |

São 56 tabelas que o gateway nunca vai ler nem limpar, entre elas `rbac_roles`, `rbac_users`,
`rbac_user_roles`, `rbac_role_endpoints`, `rbac_role_entities`, `rbac_user_groups`, `workspaces`,
`workspace_entities`, `workspace_entity_counters`, `licenses`, `license_data`, `audit_objects`,
`audit_requests`, `consumer_group_*` e `vitals_code_classes_by_workspace`. A tabela `workspaces`
ainda carrega uma linha — o workspace `default` do Enterprise —, inerte para o OSS.

Nada disso é suportado pela Kong: a documentação cobre upgrades dentro da mesma edição, não
Enterprise → OSS.

## Recomendações

1. **Exportar e reimportar com decK** (recomendado). Em vez de reaproveitar o banco, faça
   `deck gateway dump` no Enterprise, suba o APIP com um banco **novo e vazio**, e aplique com
   `deck gateway sync`. A configuração é migrada, o schema nasce limpo e o ledger de migrations
   fica coerente. É mais trabalho, e é o único caminho que resulta em um ambiente sustentável.

2. **Reaproveitar o banco como neste laboratório**, aceitando a dívida. Aceitável para um teste,
   uma prova de conceito ou uma janela curta de transição. Faça `pg_dump` antes, e documente que
   aquele banco carrega schema Enterprise órfão.

3. **Limpar o schema Enterprise manualmente** depois da troca. Não recomendado: exige conhecer as
   dependências entre as tabelas, não é suportado, e o resultado ainda difere de um banco nascido
   no OSS.

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
