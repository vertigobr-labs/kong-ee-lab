# Kong EE local (k3d) - modo normal, docker compose <!-- omit in toc -->

Passos para executar Kong EE localmente em modo tradicional (com database).

- [Pré-requisitos](#pré-requisitos)
- [Kong EE local (com database)](#kong-ee-local-com-database)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux), com plugin `docker compose`

## Kong EE local (com database)

Este projeto possui um `docker-compose-ee.yml` pronto para uso:

```sh
export KONG_LICENSE_DATA='......'  # deixe vazia se for rodar em free mode
# roda o kong
docker compose -f docker-compose-ee.yml up
```

Endpoints do Kong:

* Kong Gateway: http://localhost:8000
* Kong Manager (admin UI): http://localhost:8002
* Kong Admin API: http://localhost:8001

O Kong Manager irá exigir autenticação (login `kong_admin` e senha `vert1234`).
