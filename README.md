# kong-ee-lab <!-- omit in toc -->

Instruções para rodar Kong Gateway (Enterprise) usando o chart oficial da Kong, tanto em ambiente local (via docker-compose ou k3d) quanto em ambiente remoto (via Okteto), tanto nos modos "normal" quanto "db-less" (Ingress Controller).

- [Definições](#definições)
  - [Kong Gateway OSS vs Kong Gateway (Free Mode) vs Kong Gateway (Enterprise)](#kong-gateway-oss-vs-kong-gateway-free-mode-vs-kong-gateway-enterprise)
  - [Kong "normal" vs Kong db-less vs Kong Ingress Controller](#kong-normal-vs-kong-db-less-vs-kong-ingress-controller)
  - [Execução local vs Execução remota (Okteto)](#execução-local-vs-execução-remota-okteto)
- [Instruções de instalação - Docker (docker-compose)](#instruções-de-instalação---docker-docker-compose)
  - [Kong EE local em modo "normal"](#kong-ee-local-em-modo-normal)
- [Instruções de instalação - Kubernetes (k3d)](#instruções-de-instalação---kubernetes-k3d)
  - [Kong Gateway local (k3d) em modo "db-less" (ingress controller)](#kong-gateway-local-k3d-em-modo-db-less-ingress-controller)
  - [Kong Gateway local (k3d) em modo "normal" (com database)](#kong-gateway-local-k3d-em-modo-normal-com-database)
  - [Kong for Kubernetes Enterprise local (k3d) em modo "Ingress Controller" (db-less)](#kong-for-kubernetes-enterprise-local-k3d-em-modo-ingress-controller-db-less)
  - [Kong Gateway on Kubernetes local (k3d)](#kong-gateway-on-kubernetes-local-k3d)
  - [Kong Gateway em cluster Okteto](#kong-gateway-em-cluster-okteto)

## Definições

### Kong Gateway OSS vs Kong Gateway (Free Mode) vs Kong Gateway (Enterprise)

O Kong Gateway (antigo "Enterprise") pode ser executado em "Free Mode" (i.e. sem licenciamento) ou em modo "Enterprise" (com licenciamento), bastando fornecer um arquivo de licença válido. Confira [as diferenças entre Free Mode e Enterprise](https://docs.konghq.com/gateway/latest/plan-and-deploy/licenses/).

Tipicamente no Kong Gateway em "Free Mode" o Kong Manager está disponível (embora sem autenticação), mas todos os demais componentes do Kong Gateway (Dev Portal, Vitals etc.) não funcionam. Em "Free Mode" não há RBAC e isto afeta diversas funcionalidades, mas a presença da UI do Manager é de grande ajuda.

Já o Kong Gateway OSS não possui nenhum elemento de interface gráfica, podendo contudo ser administrado via Admin API ou por produtos de terceiros que a utilizem (como o Konga).

### Kong "normal" vs Kong db-less vs Kong Ingress Controller

Um ambiente "normal" do Kong permite sua configuração via Admin API. A Admin API é, na verdade, o backend utilizado tanto pelo Kong Manager quanto pelo Konga (alternativa ao Kong Manager desenvolvida pela comunidade). **Neste modo de operação o Kong precisa de um database associado**.

Um ambiente db-less do Kong tem sua configuração totalmente declarativa, dispensando um banco de dados. Um caso particular de Kong db-less é o Kong Ingress Controller, cuja configuração é feita por objetos no Kubernetes (CRDs).

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

## Instruções de instalação - Kubernetes (k3d)

### Kong Gateway local (k3d) em modo "db-less" (ingress controller)

Veja em [KONG_CE_LOCAL_DBLESS.md](KONG_CE_LOCAL_DBLESS.md) os passos para executar Kong Gateway localmente em cluster k3d como ingress controller. Três portas são expostas (8000, 9000 e 9001) para o Kong e sua Admin API, respectivamente.

### Kong Gateway local (k3d) em modo "normal" (com database)

Veja em [KONG_EE_LOCAL_DB_FREE.md](KONG_EE_LOCAL_DB_FREE.md) os passos para executar Kong Gateway localmente em cluster k3d, com database e em Free Mode (Kong OSS + Kong Manager, mas sem Dev Portal). Um exemplo protegendo a administração com basic-auth é fornecido.

Veja em [KONG_EE_LOCAL_DB.md](KONG_EE_LOCAL_DB.md) os passos para executar Kong Gateway localmente em cluster k3d, com database, RBAC e usando uma licença válida.

### Kong for Kubernetes Enterprise local (k3d) em modo "Ingress Controller" (db-less)

O Kong for Kubernetes Enterprise é uma instalação do Kong Gateway restrita ao Kong Ingress Controller (db-less) e seus plugins Enterprise. A configuração do Kong é feita por CRDs no Kubernetes e a Admin API é read-only, mas sendo uma instalação db-less alguns plugins podem não funcionar.

Veja em [KONG_EE_LOCAL_INGRESS.md](KONG_EE_LOCAL_INGRESS.md) os passos para executar o Kong for Kubernetes Enterprise localmente.

### Kong Gateway on Kubernetes local (k3d)

O Kong Enterprise on Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Isto significa que plugins que exigem bancos de dados irão funcionar mesmo usando o Kong Ingress Controller.

Veja em [KONG_EE_LOCAL_INGRESS_FULL.md](KONG_EE_LOCAL_INGRESS_FULL.md) os passos para executar o Kong Enterprise on Kubernetes localmente.

Veja em [KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md](KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md) os passos para executar o Kong Enterprise on Kubernetes localmente e distribuído em vários nós, separando *control plane* e *data plane*.

### Kong Gateway em cluster Okteto

O [Okteto](https://www.okteto.com/) é um serviço em nuvem que melhora consideravelmente a experiência de desenvolvedores que precisam lidar com clusters Kubernetes.

Veja em [KONG_EE_OKTETO_DB_FREEMODE.md](KONG_EE_OKTETO_DB_FREEMODE.md) os passos para executar Kong Gateway em Free Mode remotamente em cluster Okteto.

Veja em [KONG_EE_OKTETO_DB_LICENSE.md](KONG_EE_OKTETO_DB_LICENSE.md) os passos para executar Kong Gateway com licença válida remotamente em cluster Okteto.
