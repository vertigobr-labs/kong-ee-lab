# Kong Enterprise on Kubernetes (k3d) - Ingress Controller <!-- omit in toc -->

O Kong Enterprise on Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Ambientes de produção devem distribuídos em várias instâncias, separando os módulos de controle dos módulos de dados (control plane e data plane).

Passos para executar Kong Enterprise on Kubernetes localmente em um cluster k3d que simule uma instalação distribuída em vários nós:

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Enterprise on Kubernetes:](#instalar-kong-enterprise-on-kubernetes)
- [Acessar aplicações:](#acessar-aplicações)
- [Configurar o Kong Enterprise on Kubernetes](#configurar-o-kong-enterprise-on-kubernetes)
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
# start local registry and Docker Hub mirror
./registry/start-registry.sh
# roda um cluster k3d (vai suportar traefik e kong como ingress controllers)
k3d cluster create kong-local \
  -p "8000:80@loadbalancer" -p "9000:30080@agent[0]" \
  --servers 3 --agents 1 \
  --registry-use k3d-registry.localhost \
  --registry-config ./registry/registries.yaml
# usa este cluster
kubectl config use-context k3d-kong-local
kubectl cluster-info
```

## Configurar licença e secrets

Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo para criar os diversos secrets necessários/recomendados:

```sh
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
export ADMIN_COOKIE_SECRET=$(pwgen 15 1)   # ou qualquer string desejada
export KONGPWD=$(pwgen 15 1)               # senha superadmin do Kong
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=$KONGPWD
echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong","cookie_domain":"manager.localhost"}' > admin_gui_session_conf
echo '{"cookie_name":"portal_session","cookie_samesite":"Strict","secret":"'$SESSION_COOKIE_SECRET'","cookie_secure":false,"storage":"kong","cookie_domain":"portal.localhost"}' > portal_session_conf
kubectl create secret generic kong-session-config \
  --from-file=admin_gui_session_conf=admin_gui_session_conf \
  --from-file=portal_session_conf=portal_session_conf
echo "kong_admin password: $KONGPWD"
```

## Instalar Kong Enterprise on Kubernetes:

Para instalar o Kong Enterprise on Kubernetes *com uma licença válida* usando o chart oficial e separando *control plane* e *data plane*:

```sh
helm upgrade -i kong -f values-ee-ingress-full-dist-cp.yaml kong/kong
helm upgrade -i kong-data -f values-ee-ingress-full-dist-dp.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:9000/
* Kong Developer Portal:
  * http://portal.localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/

## Configurar o Kong Enterprise on Kubernetes

O Kong Enterprise on Kubernetes pode ser configurado tanto pelo Kong Manager quanto pelos objetos (CRDs) do Kubernetes. Exemplo:

```sh
# cria serviço e rota no Kong via CRDs
kubectl apply -f kic/
```

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
```
