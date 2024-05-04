# Kong CE local (k3d) - modo normal, docker compose <!-- omit in toc -->

Passos para executar Kong CE localmente em modo tradicional (com database).

- [Pré-requisitos](#pré-requisitos)
- [Kong CE local (com database)](#kong-ce-local-com-database)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com plugin `docker compose`

## Kong CE local (com database)

Este projeto possui um `docker-compose.yml` pronto para uso:

```sh
docker compose up
```

Se quiser subir separadamente cada componente:

```sh
# sobe e inicializa o BD
docker compose up -d kong-db
docker compose up kong-init
# roda o kong
docker compose up kong
```

Endpoints do Kong:

* Kong Gateway: http://localhost:8000
* Kong Manager (Admin UI): http://localhost:8002
* Kong Admin API: http://localhost:8001
