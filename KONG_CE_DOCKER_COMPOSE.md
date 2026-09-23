# Kong Gateway (OSS) local com docker compose <!-- omit in toc -->

Passos para executar o Kong Gateway (OSS) localmente em modo tradicional (com database Postgres),
usando apenas o `docker compose`.

- [Pré-requisitos](#pré-requisitos)
- [Subir o Kong](#subir-o-kong)
- [Acessar aplicações](#acessar-aplicações)
- [Testar](#testar)
- [Remover (opcional)](#remover-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com o plugin `docker compose`

## Subir o Kong

Este projeto possui um `docker-compose.yml` pronto para uso, com Kong Gateway 3.9.3 e Postgres 17:

```sh
docker compose up
```

Se quiser subir separadamente cada componente:

```sh
# sobe o banco e roda as migrations
docker compose up -d kong-db
docker compose up kong-init
# roda o kong
docker compose up -d kong
```

## Acessar aplicações

- Kong Gateway: `http://localhost:8000`
- Kong Admin API: `http://localhost:8001`
- Kong Manager (Admin UI): `http://localhost:8002`

O Kong Manager está disponível no Kong Gateway OSS desde a versão 3.5, sem autenticação
(RBAC é um recurso Enterprise).

## Testar

```sh
# versão em execução
curl -s localhost:8001/ | jq -r .version

# proxy ainda sem rotas configuradas
curl -s localhost:8000/
```

## Remover (opcional)

```sh
docker compose down
# para apagar também o volume do Postgres
docker compose down -v
```
