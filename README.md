# kong-ee-lab <!-- omit in toc -->

Instruções para rodar Kong Gateway (Enterprise) usando o chart oficial da Kong, tanto em ambiente local (via docker-compose ou k3d) quanto em ambiente remoto (via Okteto), tanto nos modos "normal" quanto "db-less" (Ingress Controller).

- [Definições](#definições)
  - [Kong Gateway vs Kong Gateway Enterprise (Free Mode) vs Kong Gateway Enterprise](#kong-gateway-vs-kong-gateway-enterprise-free-mode-vs-kong-gateway-enterprise)
  - [Kong "tradicional" vs Kong db-less vs Kong Ingress Controller](#kong-tradicional-vs-kong-db-less-vs-kong-ingress-controller)
  - [Kong no Kubernetes](#kong-no-kubernetes)
  - [Execução local vs Execução remota (Okteto)](#execução-local-vs-execução-remota-okteto)
- [Instruções de instalação - Docker (docker-compose)](#instruções-de-instalação---docker-docker-compose)
  - [Kong EE local em modo "normal"](#kong-ee-local-em-modo-normal)
- [Instruções de instalação - Kubernetes (k3d / vkpr)](#instruções-de-instalação---kubernetes-k3d--vkpr)
  - [Kong Gateway (OSS) local (k3d) em modo "db-less" (ingress controller)](#kong-gateway-oss-local-k3d-em-modo-db-less-ingress-controller)
  - [Kong Gateway Enterprise local (k3d) em modo "normal" (com database)](#kong-gateway-enterprise-local-k3d-em-modo-normal-com-database)
  - [Kong Gateway Enterprise local (k3d) em modo "Ingress Controller" (db-less)](#kong-gateway-enterprise-local-k3d-em-modo-ingress-controller-db-less)
  - [Kong Gateway on Kubernetes local (k3d)](#kong-gateway-on-kubernetes-local-k3d)
  - [Kong Gateway em cluster Okteto](#kong-gateway-em-cluster-okteto)

## Definições

### Kong Gateway vs Kong Gateway Enterprise (Free Mode) vs Kong Gateway Enterprise

O Kong Gateway Enterprise pode ser executado em "Free Mode" (i.e. sem licenciamento) ou em modo "full" (com licenciamento), bastando fornecer um arquivo de licença válido. Confira [as diferenças entre Free Mode e Enterprise](https://docs.konghq.com/gateway/latest/plan-and-deploy/licenses/).

Tipicamente no Kong Gateway Enterprise em "Free Mode" o Kong Manager está disponível (embora sem autenticação), mas todos os demais componentes licenciados do Kong Gateway (como os plugins Enterprise) não funcionam. Em "Free Mode" não há RBAC e isto afeta diversas funcionalidades, mas a presença da UI do Manager é de grande ajuda.

Já o Kong Gateway (open-source), a partir da versão 3.5, também possui uma interface gráfica. Portanto a administração feita via Admin API ou por produtos de terceiros (como o Konga) não é mais necessária.

### Kong "tradicional" vs Kong db-less vs Kong Ingress Controller

Um ambiente "tradicional" do Kong permite sua configuração via Admin API. A Admin API é, na verdade, o backend utilizado tanto pelo Kong Manager quanto pelo Konga (alternativa ao Kong Manager desenvolvida pela comunidade). **Neste modo de operação o Kong precisa de um database associado**.

Um ambiente db-less do Kong tem sua configuração totalmente declarativa, dispensando um banco de dados. Um caso particular de Kong db-less é o Kong Ingress Controller, cuja configuração é feita por objetos no Kubernetes (CRDs).

### Kong no Kubernetes

No Kubernetes há [duas opções principais](https://docs.konghq.com/gateway/latest/install/kubernetes/deployment-options/) de executar o Kong Gateway:

- Modo db-less como Ingress Controller (como já mencionamos)
- Modo tradicional (com database) com ou sem o Ingress Controller

O Kong suporta ainda várias outras topologias que não iremos explorar aqui (como modo Híbrido ou subordinado ao Kong Konnect).

### Execução local vs Execução remota (Okteto)

Para execução local na estação de trabalho este repositório possui diversos exemplos:

* Usando o `docker-compose` para subir uma composição de containers especificada em [docker-compose.yml](docker-compose.yml);

* Usando o `k3d` para subir um cluster kubernetes local e descartável.

O k3d é um utilitário que permite simular um cluster multi-node dentro de um docker engine comum, permitindo trabalhar localmente com as ferramentas kubernetes. *Importante: estamos atualizando os exemplos para utilizarem o [`vkpr`](https://docs.vkpr.net/) para rodar o k3d com algumas configurações pré-definidas*.

Para execução remota em um serviço de nuvem gratuito fornecemos neste repositório exemplos usando o `Okteto`.

O [Okteto](https://okteto.com) é um ambiente self-service de desenvolvimento em kubernetes na nuvem, gratuito para clusters de até 4Gb de RAM. O Okteto permite trabalhar de forma consistente com ambientes de desenvolvimento remotos. 

## Instruções de instalação - Docker (docker-compose)

### Kong EE local em modo "normal"

Este projeto possui um `docker-compose.yml` pronto para uso:

```sh
export KONG_LICENSE_DATA='......'  # deixe vazia se for rodar em free mode
# sobe e inicializa o BD
docker-compose up -d kong-db
docker-compose up kong-init
# roda o kong
docker-compose up kong
```

Endpoints do Kong:

* Kong Gateway: http://localhost:8000
* Kong Manager (admin UI): http://localhost:8002
* Kong Admin API: http://localhost:8001

## Instruções de instalação - Kubernetes (k3d / vkpr)

### Kong Gateway (OSS) local (k3d) em modo "db-less" (ingress controller)

Veja em [KONG_CE_LOCAL_DBLESS.md](KONG_CE_LOCAL_DBLESS.md) os passos para executar Kong Gateway localmente em cluster k3d como ingress controller. Três portas são expostas (8000, 9000 e 9001) para o Kong e sua Admin API e GUI, respectivamente.

### Kong Gateway Enterprise local (k3d) em modo "normal" (com database)

Veja em [KONG_EE_LOCAL_DB_FREE.md](KONG_EE_LOCAL_DB_FREE.md) os passos para executar Kong Gateway localmente em cluster k3d, com database e em Free Mode (Kong OSS + Kong Manager). Um exemplo adicional protegendo a administração com basic-auth é fornecido.

Veja em [KONG_EE_LOCAL_DB.md](KONG_EE_LOCAL_DB.md) os passos para executar Kong Gateway localmente em cluster k3d, com database, RBAC, Ingress Controller e usando uma licença válida. Com RBAC habilitado o Kong Manager exige autenticação (usuário "kong_admin"). Um exemplo adicional com a configuração de uma API via CRDs de Kubernetes é utilizado.

### Kong Gateway Enterprise local (k3d) em modo "Ingress Controller" (db-less)

O Kong Gateway restrito ao modo Ingress Controller (db-less) suporta a ampla maioria dos plugins Enterprise (exceto aquele incompatíveis com "db-less"). A configuração do Kong é feita por CRDs no Kubernetes e a Admin API é read-only, mas o Admin UI (Manager) serve para estudar a configuração resultante dos CRDs.

Veja em [KONG_EE_LOCAL_INGRESS.md](KONG_EE_LOCAL_INGRESS.md) os passos para executar o Kong em modo Ingress Controller (db-less) localmente.

### Kong Gateway on Kubernetes local (k3d)

O Kong Gateway Enterprise no Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Isto significa que configurações podem ser feitas pela UI ou via CRDs.

Topologias mais elaboradas podem separar control plane e data plane do Kong.

Veja em [KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md](KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md) os passos para executar o Kong Enterprise on Kubernetes localmente (simulando distribuição em vários nós), separando *control plane* e *data planes*.

### Kong Gateway em cluster Okteto

O [Okteto](https://www.okteto.com/) é um serviço em nuvem que melhora consideravelmente a experiência de desenvolvedores que precisam lidar com clusters Kubernetes.

Veja em [KONG_EE_OKTETO_DB_FREEMODE.md](KONG_EE_OKTETO_DB_FREEMODE.md) os passos para executar Kong Gateway em Free Mode remotamente em cluster Okteto.

Veja em [KONG_EE_OKTETO_DB_LICENSE.md](KONG_EE_OKTETO_DB_LICENSE.md) os passos para executar Kong Gateway com licença válida remotamente em cluster Okteto.
