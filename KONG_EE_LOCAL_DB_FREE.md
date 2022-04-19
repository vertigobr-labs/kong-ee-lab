# Kong EE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway localmente em um cluster k3d e em modo "normal" (com database) e em Free Mode.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Instalar Kong Gateway em Free Mode](#instalar-kong-gateway-em-free-mode)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- k3d
- Helm
- Kubectl

**Importante:** este exemplo também assume que nomes "*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

```
127.0.0.1 portal.localhost api.portal.localhost manager.localhost api.manager.localhost kong.localhost registry.localhost
```

Nota: estamos usando o k3d para subir um kubernetes local, mas outras alternativas como o minikube também devem funcionar. 

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d

O k3d cria um cluster já com o Traefik Ingress Controller, o qual estará publicado em porta local arbitrária (8000): 

```sh
# roda registry local e um mirror do Docker Hub
./registry/start-registry.sh
# roda um cluster k3d usando o mirror para cache (recomendado)
k3d cluster create kong-local \
  -p "8000:80@loadbalancer" \
  --registry-use k3d-registry.localhost \
  --registry-config ./registry/registries.yaml
# usa este cluster
kubectl config use-context k3d-kong-local
kubectl cluster-info
```

## Instalar Kong Gateway em Free Mode

Para instalar Kong Gateway em "Free Mode" (i.e. sem uma licença) com o chart oficial:

```sh
helm upgrade -i kong -f values-ee-db.yaml kong/kong --skip-crds
```

Em `values-ee-db.yaml` é ativado o modo "enterprise" mas a *secret* com licença é ignorada.

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://kong.localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/

Nota: em free mode o Dev Portal não deveria estar disponível e é possível que "desapareça" em releases posteriores.

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
# se quiser zerar o banco
kubectl delete pvc data-kong-postgresql-0
```
