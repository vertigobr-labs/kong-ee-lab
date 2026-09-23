# kong-ee-lab <!-- omit in toc -->

Instruções para rodar o Kong Gateway (OSS) em ambiente local, com `docker compose` ou em um
cluster Kubernetes local (k3d).

- [Definições](#definições)
- [Pré-requisitos](#pré-requisitos)
- [Exemplos](#exemplos)
- [Versões](#versões)

## Definições

Um ambiente "tradicional" do Kong persiste sua configuração em um database Postgres e a expõe via
Admin API — que é também o backend do Kong Manager.

Um ambiente "db-less" tem a configuração totalmente declarativa, dispensando o banco. No
Kubernetes esse é o modo do Kong Ingress Controller, em que a configuração vem de objetos do
cluster (CRDs e annotations).

Desde a versão 3.5 o Kong Gateway OSS já inclui o Kong Manager, dispensando UIs de terceiros.

## Pré-requisitos

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com o plugin `docker compose`
- Para o exemplo em Kubernetes, o `vkdr` (que já traz `k3d`, `helm` e `kubectl` em `~/.vkdr/bin`):

```sh
curl -sL https://get-vkdr.vee.codes | bash
vkdr init
```

## Exemplos

| Cenário | Runbook | Configuração |
| --- | --- | --- |
| Modo tradicional (com database), via docker compose | [KONG_CE_DOCKER_COMPOSE.md](KONG_CE_DOCKER_COMPOSE.md) | `docker-compose.yml` |
| Modo db-less (ingress controller), em cluster k3d | [KONG_CE_LOCAL_DBLESS.md](KONG_CE_LOCAL_DBLESS.md) | `values-dbless.yaml` |
| Sair do "free mode" reaproveitando o database | [freemode-upgrade/](freemode-upgrade/README.md) | `freemode-upgrade/docker-compose.yml` |
| O mesmo cenário em cluster k3d, via CLI do vkdr | [freemode-upgrade/VKDR.md](freemode-upgrade/VKDR.md) | `vkdr kong install` |

O exemplo em k3d inclui a configuração de uma API por CRDs do Kubernetes, na pasta `kic/`.

## Versões

- Kong Gateway OSS `3.9.3`
- chart `kong/kong` `3.4.1`
- Postgres `17` no exemplo com docker compose

As imagens do Kong são multi-arquitetura e rodam nativamente em Macs Apple Silicon.
