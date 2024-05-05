# kong-ee-lab <!-- omit in toc -->

Este repositório contem instruções para rodar Kong Gateway em ambiente local (usando "docker compose" ou cluster kubernetes local).

Vários cenários são cobertos, incluindo a execução do Kong Gateway (OSS) e Kong Gateway Enterprise tanto nos modos "normal" quanto "db-less" (Ingress Controller).

- [Definições](#definições)
  - [Kong Gateway vs Kong Gateway Enterprise (Free Mode) vs Kong Gateway Enterprise](#kong-gateway-vs-kong-gateway-enterprise-free-mode-vs-kong-gateway-enterprise)
  - [Kong "tradicional" vs Kong db-less vs Kong Ingress Controller](#kong-tradicional-vs-kong-db-less-vs-kong-ingress-controller)
  - [Kong Gateway no Kubernetes](#kong-gateway-no-kubernetes)
  - [Docker Compose e VKDR](#docker-compose-e-vkdr)
- [Exemplos com Docker Compose](#exemplos-com-docker-compose)
  - [Kong CE local em modo "tradicional"](#kong-ce-local-em-modo-tradicional)
  - [Kong EE local em modo "tradicional"](#kong-ee-local-em-modo-tradicional)
- [Exemplos com Kubernetes em cluster local (k3d / vkdr)](#exemplos-com-kubernetes-em-cluster-local-k3d--vkdr)
  - [Kong Gateway (OSS) em modo "db-less" (ingress controller)](#kong-gateway-oss-em-modo-db-less-ingress-controller)
  - [Kong Gateway Enterprise local (k3d) em modo "normal" (com database)](#kong-gateway-enterprise-local-k3d-em-modo-normal-com-database)
  - [Kong Gateway Enterprise em modo DB-less ("Ingress Controller")](#kong-gateway-enterprise-em-modo-db-less-ingress-controller)
  - [Kong Gateway on Kubernetes local (k3d)](#kong-gateway-on-kubernetes-local-k3d)
  - [Kong Gateway em cluster Okteto](#kong-gateway-em-cluster-okteto)

## Definições

### Kong Gateway vs Kong Gateway Enterprise (Free Mode) vs Kong Gateway Enterprise

O Kong Gateway Enterprise pode ser executado em "Free Mode" (i.e. sem licenciamento) ou em modo "full" (com licenciamento), bastando fornecer um arquivo de licença válido. Confira [as diferenças entre Free Mode e Enterprise](https://docs.konghq.com/gateway/latest/plan-and-deploy/licenses/).

Tipicamente no Kong Gateway Enterprise em "Free Mode" o Kong Manager está disponível (embora sem autenticação), mas todos os demais componentes licenciados do Kong Gateway (como os plugins Enterprise) não funcionam. Em "Free Mode" não há RBAC e isto afeta diversas funcionalidades, mas a presença da UI do Manager é de grande ajuda.

Já o Kong Gateway (open-source), a partir da versão 3.5, também possui uma interface gráfica. Portanto a administração feita via Admin API ou por produtos de terceiros (como o Konga) não é mais necessária.

### Kong "tradicional" vs Kong db-less vs Kong Ingress Controller

Um ambiente "tradicional" do Kong persiste sua configuração em database e a expõe via Admin API. A própria Admin API é o backend utilizado pelo Kong Manager. **Neste modo de operação o Kong está associado um database Postgres**.

Um ambiente db-less do Kong tem sua configuração totalmente declarativa, dispensando um banco de dados. Um caso particular de Kong db-less é o Kong Ingress Controller, cuja configuração é feita por objetos no Kubernetes (CRDs).

### Kong Gateway no Kubernetes

No Kubernetes há [duas opções principais](https://docs.konghq.com/gateway/latest/install/kubernetes/deployment-options/) de executar o Kong Gateway:

- Modo db-less como Ingress Controller (como já mencionamos)
- Modo tradicional (com database de configuração), com ou sem o Ingress Controller
- Modo híbrido (com control plane e data plane separados)
- Data plane somente, subordinado ao Kong Konnect (SaaS da Kong)

Não iremos explorar nos exemplos o modo Híbrido ou Konnect.

### Docker Compose e VKDR

Para execução local na estação de trabalho dos cenários que iremos explorar neste repositório, usaremos o `docker compose` e o `vkdr` (que é um utilitário que facilita a execução de clusters k3d).

* Os exemplos usando o `docker compose` são bem mais simples e dispensam o uso de Kubernetes;

* Os exemplos usando o kubernetes serão baseados no `k3d` e na CLI `vkdr` (um utilitário da Vertigo que usamos em treinamentos e laboratórios).

O `vkdr` pode ser instalado com o comando abaixo:

```sh
curl -sL https://get-vkdr.vee.codes | bash
# apos instalacao iniciar a CLI uma única vez
vkdr init
```

O `k3d` (baixado pelo próprio `vkdr`) é um utilitário que permite simular um cluster multi-node dentro de um docker engine comum, permitindo faer experimentos complexos com clusters kubernetes descartáveis.

## Exemplos com Docker Compose

### Kong CE local em modo "tradicional"

Veja em [KONG_CE_DOCKER_COMPOSE](KONG_CE_DOCKER_COMPOSE.md) um exemplo para rodar Kong Gateway OSS localmente usando apenas o `docker compose`. Portas são expostas em `localhost` para o gateway (8000), sua Admin API (8001) e sua GUI (8002), respectivamente.

### Kong EE local em modo "tradicional"

Veja em [KONG_EE_DOCKER_COMPOSE](KONG_EE_DOCKER_COMPOSE.md) um exemplo para rodar Kong Gateway Enterprise localmente usando apenas o `docker compose`. Portas são expostas em `localhost` para o gateway (8000), sua Admin API (8001) e Kong Manager (8002), respectivamente.

## Exemplos com Kubernetes em cluster local (k3d / vkdr)

O `vkdr` é um utilitário que facilita a execução de clusters k3d. Ele é usado para criar clusters k3d com configurações específicas para laboratórios e treinamentos.

### Kong Gateway (OSS) em modo "db-less" (ingress controller)

Veja em [KONG_CE_LOCAL_DBLESS.md](KONG_CE_LOCAL_DBLESS.md) os passos para executar Kong Gateway localmente em cluster k3d como ingress controller. Três portas são expostas (8000, 9000 e 9001) para o Kong e sua Admin API e GUI, respectivamente.

### Kong Gateway Enterprise local (k3d) em modo "normal" (com database)

Veja em [KONG_EE_LOCAL_DB_FREE.md](KONG_EE_LOCAL_DB_FREE.md) os passos para executar Kong Gateway localmente em cluster k3d, com database e em Free Mode (Kong OSS + Kong Manager). Um exemplo adicional protegendo a administração com basic-auth é fornecido.

Veja em [KONG_EE_LOCAL_DB.md](KONG_EE_LOCAL_DB.md) os passos para executar Kong Gateway localmente em cluster k3d, com database, RBAC, Ingress Controller e usando uma licença válida. Com RBAC habilitado o Kong Manager exige autenticação (usuário "kong_admin"). Um exemplo adicional com a configuração de uma API via CRDs de Kubernetes é utilizado.

### Kong Gateway Enterprise em modo DB-less ("Ingress Controller")

Veja em [KONG_EE_LOCAL_INGRESS.md](KONG_EE_LOCAL_INGRESS.md) os passos para executar o Kong em modo Ingress Controller (db-less) no cluster local, com Admin API e Kong Manager sendo read-only.

### Kong Gateway on Kubernetes local (k3d)

O Kong Gateway Enterprise no Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Isto significa que configurações podem ser feitas pela UI ou via CRDs.

Topologias mais elaboradas podem separar control plane e data plane do Kong.

Veja em [KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md](KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md) os passos para executar o Kong Enterprise on Kubernetes localmente (simulando distribuição em vários nós), separando *control plane* e *data planes*.

### Kong Gateway em cluster Okteto

O [Okteto](https://www.okteto.com/) é um serviço em nuvem que melhora consideravelmente a experiência de desenvolvedores que precisam lidar com clusters Kubernetes.

Veja em [KONG_EE_OKTETO_DB_FREEMODE.md](KONG_EE_OKTETO_DB_FREEMODE.md) os passos para executar Kong Gateway em Free Mode remotamente em cluster Okteto.

Veja em [KONG_EE_OKTETO_DB_LICENSE.md](KONG_EE_OKTETO_DB_LICENSE.md) os passos para executar Kong Gateway com licença válida remotamente em cluster Okteto.
