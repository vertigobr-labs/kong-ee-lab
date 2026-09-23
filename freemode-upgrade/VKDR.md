# Free mode → VeeCode APIP: reaproveitando o database (VKDR) <!-- omit in toc -->

Variante do [README.md](README.md) deste diretório, trocando o `docker compose` por um cluster
Kubernetes local gerenciado pela CLI do [vkdr](https://github.com/veecode-platform/vkdr).

Aqui o roteiro **começa no fim**: parte do `kong-oss.yaml` já limpo, produzido na etapa 5 do
roteiro do compose, e cobre apenas o destino — Kong em modo standard com a imagem distroless do
APIP, e a restauração da configuração via decK contra a Admin API.

Vale a mesma observação de enquadramento do outro roteiro: sair do free mode é ao mesmo tempo um
**upgrade de release** (3.9 → 3.10+) e um **downgrade de schema** (Enterprise → OSS). O que se faz
aqui é a resposta limpa às duas direções: um banco novo, criado pelo próprio APIP, e a
configuração reaplicada por cima.

- [Pré-requisitos](#pré-requisitos)
- [Etapa 1: cluster e Kong standard](#etapa-1-cluster-e-kong-standard)
- [A imagem distroless e os init containers do chart](#a-imagem-distroless-e-os-init-containers-do-chart)
- [Etapa 2: sync do decK contra a Admin API](#etapa-2-sync-do-deck-contra-a-admin-api)
- [O Ingress Controller e o decK disputam o mesmo banco](#o-ingress-controller-e-o-deck-disputam-o-mesmo-banco)
- [Verificação](#verificação)
- [Limpeza](#limpeza)

## Pré-requisitos

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- `vkdr` **2.0.30 ou superior** (a opção `--distroless` é recente)
- [decK](https://docs.konghq.com/deck/) (testado com a v1.62)
- O arquivo `kong-oss.yaml`, gerado na etapa 5 do [README.md](README.md)

Este exemplo assume que nomes `*.localhost` resolvem para 127.0.0.1.

## Etapa 1: cluster e Kong standard

```sh
vkdr infra up
vkdr kong install -m standard -i veecode/kong -t 3.10.0-veecode.10-distroless
```

O `-m standard` sobe o Kong em modo tradicional (com database) e o `vkdr` provisiona o Postgres no
cluster automaticamente, com senhas geradas. As migrations rodam em um Job (`kong-kong-init-migrations`)
antes do gateway subir — é o equivalente ao encadeamento `bootstrap`/`up`/`finish` do compose.

Os endpoints ficam assim:

- Kong proxy: `http://localhost:8000`
- Kong Admin API: `http://manager.localhost:8000`
- Kong Manager: `http://manager.localhost:8000/manager`

```sh
curl -s http://manager.localhost:8000/ | jq '{version, edition}'
# {"version": "3.10.0-veecode.10", "edition": "community"}
```

## A imagem distroless e os init containers do chart

O chart oficial do Kong ainda não lida automaticamente com uma imagem distroless sem ajuste, e o
erro é pouco óbvio:

```pre
Init:CrashLoopBackOff

failed to create containerd task: OCI runtime create failed:
exec: "rm": executable file not found in $PATH
```

O chart declara dois init containers que assumem um sistema de arquivos convencional:

- `clear-stale-pid`, que roda `rm -vrf $(KONG_PREFIX)/pids`
- `wait-for-db`, que roda `/bin/bash -c "until kong start; do ...; done"`

A imagem distroless não tem `rm` nem `/bin/bash`, então o pod nem chega a iniciar.

O `vkdr` resolve isso com a opção `--distroless`, que aponta o `clear-stale-pid` para uma imagem
`busybox` e desliga o `wait-for-db`. **Não é preciso passar a opção**: ela liga sozinha quando o
nome ou a tag da imagem contém `distroless`, que é o caso do comando acima. Para forçar:

```sh
vkdr kong install -m standard --distroless -i veecode/kong -t 3.10.0-veecode.10-distroless
```

Dá para confirmar o que foi aplicado:

```sh
kubectl -n vkdr get deploy kong-kong \
  -o jsonpath='{range .spec.template.spec.initContainers[*]}{.name}: {.image}{"\n"}{end}'
# clear-stale-pid: busybox:1.36      <- e nenhum wait-for-db
```

## Etapa 2: sync do decK contra a Admin API

O `kong-oss.yaml` já passou pelo `clean-enterprise.sh` no outro roteiro, então não precisa de
tratamento adicional. Mas ele precisa de **tags** — a razão está na seção seguinte:

```sh
yq '
  (.services // []) |= map(.tags = ["deck-managed"]
    | (.routes  // []) |= map(.tags = ["deck-managed"])
    | (.plugins // []) |= map(.tags = ["deck-managed"]))
  | (.consumers // []) |= map(.tags = ["deck-managed"])
' kong-oss.yaml > kong-oss-tagged.yaml
```

E então o ciclo normal do decK, apontando para a Admin API em `manager.localhost`:

```sh
deck gateway validate kong-oss-tagged.yaml --kong-addr http://manager.localhost:8000
deck gateway diff     kong-oss-tagged.yaml --kong-addr http://manager.localhost:8000 \
  --select-tag deck-managed
deck gateway sync     kong-oss-tagged.yaml --kong-addr http://manager.localhost:8000 \
  --select-tag deck-managed
```

```pre
Summary:
  Created: 6
  Updated: 0
  Deleted: 0
```

## O Ingress Controller e o decK disputam o mesmo banco

Esta é a diferença real entre este roteiro e o do compose, e vale entender antes de rodar um
`sync` em um cluster que importa.

O `vkdr kong install` sobe o Kong **com o Ingress Controller ligado** — e é ele que serve o próprio
`manager.localhost`, criando no Kong os services, upstreams e targets que expõem a Admin API e o
Manager. Ou seja: o KIC escreve configuração no mesmo banco em que o decK vai escrever.

Um `deck gateway diff` sem escopo enxerga essas entidades como "sobrando" no gateway:

```pre
deleting service vkdr.kong-kong-manager.8002
deleting service vkdr.kong-kong-admin.8001
deleting upstream kong-kong-manager.vkdr.8002.svc
deleting upstream kong-kong-admin.vkdr.8001.svc
Summary:
  Created: 6
  Updated: 0
  Deleted: 8
```

Um `sync` assim **apagaria o endpoint pelo qual o próprio decK está falando** — e o KIC iria
recriá-lo logo em seguida, deixando o ambiente oscilando.

O KIC marca tudo o que cria com a tag `managed-by-ingress-controller`. A solução é escopar o decK
por tag, como na etapa 2: marque as suas entidades com uma tag própria e passe `--select-tag`.
O decK então só enxerga e gerencia o que carrega aquela tag, e ignora o que é do KIC —
`Deleted: 0`.

Isso vale para qualquer cluster em que o KIC e o decK convivam, não só para este laboratório.

## Verificação

Configuração no ar, com o `key-auth` sendo aplicado:

```sh
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/cep/20020080/json   # 401
curl -s -H "apikey: segredo123" http://localhost:8000/cep/20020080/json | jq -r .logradouro
# Avenida Marechal Câmara
```

Admin API intacta, ou seja, o KIC não foi atropelado:

```sh
curl -s -o /dev/null -w "%{http_code}\n" http://manager.localhost:8000/   # 200
```

E o banco, que é o ponto de todo o exercício:

```sh
kubectl -n vkdr exec vkdr-pg-cluster-1 -- \
  psql -U postgres -d kong -tAc \
  "select count(*) from information_schema.tables where table_schema='public'"
# 35

kubectl -n vkdr exec vkdr-pg-cluster-1 -- \
  psql -U postgres -d kong -tAc \
  "select count(*) from schema_meta where subsystem like 'enterprise%'"
# 0
```

**35 tabelas e zero subsistemas `enterprise*`** — o mesmo resultado do caminho B do roteiro com
docker compose, e nenhuma tabela fantasma. O banco nasceu no APIP e nunca viu o schema Enterprise.

## Limpeza

```sh
vkdr kong remove
vkdr infra stop
```
