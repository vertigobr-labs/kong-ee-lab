# kong-ee-lab <!-- omit in toc -->

Este repositório contém instruções para rodar o **Kong Gateway (OSS)** em ambiente local, usando
`docker compose` ou um cluster Kubernetes local (k3d).

Os exemplos de Kong Gateway Enterprise que existiam aqui foram arquivados — veja
[Enterprise, Konnect e o archive](#enterprise-konnect-e-o-archive).

- [Definições](#definições)
  - [Kong "tradicional" vs Kong db-less vs Kong Ingress Controller](#kong-tradicional-vs-kong-db-less-vs-kong-ingress-controller)
  - [Kong Gateway no Kubernetes](#kong-gateway-no-kubernetes)
  - [Docker Compose e VKDR](#docker-compose-e-vkdr)
- [Exemplos](#exemplos)
  - [Kong Gateway (OSS) com docker compose](#kong-gateway-oss-com-docker-compose)
  - [Kong Gateway (OSS) em k3d, modo db-less](#kong-gateway-oss-em-k3d-modo-db-less)
- [Enterprise, Konnect e o archive](#enterprise-konnect-e-o-archive)
- [Versões](#versões)

## Definições

### Kong "tradicional" vs Kong db-less vs Kong Ingress Controller

Um ambiente "tradicional" do Kong persiste sua configuração em database e a expõe via Admin API.
A própria Admin API é o backend utilizado pelo Kong Manager. **Neste modo de operação o Kong está
associado a um database Postgres.**

Um ambiente db-less do Kong tem sua configuração totalmente declarativa, dispensando um banco de
dados. Um caso particular de Kong db-less é o Kong Ingress Controller, cuja configuração é feita
por objetos no Kubernetes (CRDs).

A partir da versão 3.5 o Kong Gateway (open-source) também possui uma interface gráfica (Kong
Manager). Portanto a administração feita via Admin API ou por produtos de terceiros (como o Konga)
não é mais necessária.

### Kong Gateway no Kubernetes

No Kubernetes há [duas opções principais](https://docs.konghq.com/gateway/latest/install/kubernetes/deployment-options/)
de executar o Kong Gateway:

- Modo db-less como Ingress Controller (como já mencionamos)
- Modo tradicional (com database de configuração), com ou sem o Ingress Controller

Há ainda o modo híbrido (control plane e data plane separados) e o data plane subordinado ao Kong
Konnect. Ambos dependem do Kong Gateway Enterprise e não são cobertos pelos exemplos atuais —
veja o [roadmap do Konnect](KONNECT_ROADMAP.md).

### Docker Compose e VKDR

Para execução local na estação de trabalho usaremos o `docker compose` e o `vkdr` (um utilitário
da Vertigo que facilita a execução de clusters k3d).

- Os exemplos usando o `docker compose` são bem mais simples e dispensam o uso de Kubernetes.
- Os exemplos usando Kubernetes são baseados no `k3d` e na CLI `vkdr`.

O `vkdr` pode ser instalado com o comando abaixo:

```sh
curl -sL https://get-vkdr.vee.codes | bash
# apos instalacao iniciar a CLI uma única vez
vkdr init
```

O `k3d` (baixado pelo próprio `vkdr`) permite simular um cluster multi-node dentro de um docker
engine comum, permitindo fazer experimentos complexos com clusters kubernetes descartáveis.

## Exemplos

### Kong Gateway (OSS) com docker compose

Veja em [KONG_CE_DOCKER_COMPOSE.md](KONG_CE_DOCKER_COMPOSE.md) um exemplo para rodar o Kong
Gateway localmente em modo tradicional (com database Postgres), usando apenas o `docker compose`.
Portas são expostas em `localhost` para o gateway (8000), sua Admin API (8001) e o Kong Manager
(8002).

### Kong Gateway (OSS) em k3d, modo db-less

Veja em [KONG_CE_LOCAL_DBLESS.md](KONG_CE_LOCAL_DBLESS.md) os passos para executar o Kong Gateway
em um cluster k3d local como ingress controller. Três portas são expostas (8000, 9000 e 9001) para
o gateway, sua Admin API e o Kong Manager, respectivamente. O exemplo inclui a configuração de uma
API por CRDs do Kubernetes (pasta `kic/`).

## Enterprise, Konnect e o archive

A Kong desencoraja hoje instalações do Kong Gateway Enterprise com control plane próprio,
direcionando esses cenários para o [Konnect](https://konghq.com/products/kong-konnect). Por isso
todos os exemplos Enterprise deste repositório foram movidos para
[`archive/`](archive/README.md), onde ficam congelados e sem manutenção.

Os cenários Konnect que os substituirão estão listados em
[KONNECT_ROADMAP.md](KONNECT_ROADMAP.md) — nenhum deles foi construído ainda.

## Versões

Os exemplos atuais usam:

- Kong Gateway OSS `3.9.3` (a versão mais recente da linha OSS; não existe 3.10+)
- chart `kong/kong` `3.4.1`
- Postgres `17` no exemplo com docker compose

As imagens atuais do Kong são multi-arquitetura (`linux/amd64` e `linux/arm64`) e rodam
nativamente em Macs Apple Silicon, sem emulação e sem necessidade de tags `-alpine`.
