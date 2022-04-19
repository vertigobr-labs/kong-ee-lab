# Kong for Kubernetes Enterprise (k3d) - Ingress Controller <!-- omit in toc -->

O Kong for Kubernetes Enterprise é uma instalação do Kong Gateway restrita a **apenas o Kong Ingress Controller (db-less) e seus plugins Enterprise**. Passos para executar Kong for Kubernetes Enterprise localmente em um cluster k3d:

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença](#configurar-licença)
- [Instalar Kong for Kubernetes Enterprise:](#instalar-kong-for-kubernetes-enterprise)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

**Importante:** algumas instruções diferem quando a instalação é em "Free Mode" ou licenciada.

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

O comando k3d abaixo cria um cluster já com o Traefik Ingress Controller, o qual estará publicado em porta local arbitrária (8000) e atenderá a aplicações web "comuns", enquanto a porta 9000 está reservada para o Kong Ingress Controller: 

```sh
# roda registry local e um mirror do Docker Hub
./registry/start-registry.sh
# roda um cluster k3d (vai suportar traefik e kong como ingress controllers)
k3d cluster create kong-local \
  -p "8000:80@loadbalancer" -p "9000:30080@agent[0]" --agents 1 \
  --registry-use k3d-registry.localhost \
  --registry-config ./registry/registries.yaml
# usa este cluster
kubectl config use-context k3d-kong-local
kubectl cluster-info
```

## Configurar licença

Usar uma licença válida irá habilitar os plugins Enterprise. Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo:

```sh
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
```

Para rodar o Kong for Kubernetes Enterprise **em "free mode"** (sem licença e com algumas funcionalidades indisponíveis) é preciso apenas aplicar uma licença "vazia":

```sh
kubectl create secret generic kong-enterprise-license --from-literal=license=
```

## Instalar Kong for Kubernetes Enterprise:

Para instalar Kong for Kubernetes Enterprise com o chart oficial:

```sh
helm upgrade -i kong -f values-ee-ingress.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:9000/
* Kong Manager:
  * http://manager.localhost:8000/

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
```
